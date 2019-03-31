defmodule DemoWeb.ArkanoidLive do
  use Phoenix.LiveView

  use DemoWeb.ArkanoidLive.Config

  alias DemoWeb.ArkanoidLive.{Blocks, Engine}

  # We use x and y fields for drawing, and since we are using as values in pixels
  # for top/left CSS properties, they refer to the coordinates of the top-left vertex
  # of the block (be it a brick, paddle, etc)
  def render(assigns) do
    ~L"""
    <div class="game-container" phx-keydown="keydown" phx-keyup="keyup" phx-target="window">
      <div class="block ball"
          style="left: <%= @ball.x - @ball.radius %>px;
                top: <%= @ball.y - @ball.radius %>px;
                width: <%= @ball.width %>px;
                height: <%= @ball.height %>px; "></div>

      <div class="block paddle"
          style="left: <%= @paddle.left %>px;
            top: <%= @paddle.top %>px;
            width: <%= @paddle.width %>px;
            height: <%= @paddle.height %>px; "></div>

      <%= for block <- @blocks, block.type in [:wall, :floor] do %>
        <div class="block <%= block.type %>"
            style="left: <%= block.left %>px;
                    top: <%= block.top %>px;
                    width: <%= block.width %>px;
                    height: <%= block.height %>px; %>; "></div>
      <% end %>

      <%= for brick <- @bricks, brick.visible == true do %>
        <div class="block brick"
            style="left: <%= brick.left %>px;
                    top: <%= brick.top %>px;
                    width: <%= brick.width %>px;
                    height: <%= brick.height %>px;
                    background: <%= Map.fetch!(brick, :color) %>; "></div>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    state = initial_state()

    socket =
      socket
      |> assign(state)
      |> assign(:blocks, Blocks.build_board(state.unit, state.unit))
      |> assign(:bricks, Blocks.build_bricks(state.unit, state.unit))

    if connected?(socket) do
      {:ok, schedule_tick(socket)}
    else
      {:ok, socket}
    end
  end

  def handle_info(:tick, socket) do
    new_socket =
      socket
      |> game_loop()
      |> schedule_tick()

    {:noreply, new_socket}
  end

  def handle_event("keydown", key, socket) do
    {:noreply, on_input(socket, key)}
  end

  def handle_event("keyup", key, socket) do
    {:noreply, on_stop_input(socket, key)}
  end

  defp game_loop(%{assigns: %{game_state: :playing}} = socket) do
    socket
    |> advance_paddle()
    |> advance_ball()
    |> check_collision()
    |> check_lost()
    |> check_victory()
  end

  defp game_loop(socket), do: socket

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, socket.assigns.tick)
    socket
  end

  defp advance_ball(%{assigns: %{ball: ball, unit: unit}} = socket) do
    new_dx = ball_horizontal(ball.x, ball.dx, ball.radius, unit)
    new_dy = ball_vertical(ball.y, ball.dy, ball.radius, unit)

    socket
    |> assign(
      :ball,
      %{ball | dx: new_dx, dy: new_dy}
      |> update_in([:x], &(&1 + new_dx))
      |> update_in([:left], &(&1 + new_dx))
      |> update_in([:y], &(&1 + new_dy))
      |> update_in([:top], &(&1 + new_dy))
    )
  end

  defp ball_horizontal(x, dx, r, u) when x + dx + r >= (@board_cols - 1) * u, do: -dx
  defp ball_horizontal(x, dx, r, u) when x + dx - r < u, do: -dx
  defp ball_horizontal(_x, dx, _r, _u), do: dx

  defp ball_vertical(y, dy, r, u) when y + dy + r > (@board_rows - 1) * u, do: -dy
  defp ball_vertical(y, dy, r, u) when y + dy - r < u, do: -dy
  defp ball_vertical(_y, dy, _r, _u), do: dy

  # Compute the closest point of intersection, if any, between the ball and obstacles (bricks and paddle)
  # and proceeds to
  defp check_collision(
         %{assigns: %{bricks: bricks, ball: ball, paddle: paddle, unit: unit}} = socket
       ) do
    # Add fields to paddle so that it has the same shape of bricks
    [paddle | bricks]
    |> Enum.filter(& &1.visible)
    |> Enum.reduce(nil, fn block, acc ->
      case {Engine.collision_point(ball.x, ball.y, ball.dx, ball.dy, ball.radius, block), acc} do
        {nil, _} ->
          acc

        {p, nil} ->
          build_closest(block, p, ball)

        {p, %{distance: distance}} ->
          new_distance = Engine.compute_distance({p.x, p.y}, {ball.x, ball.y})

          if new_distance < distance do
            build_closest(block, p, ball)
          else
            acc
          end
      end
    end)
    |> case do
      nil ->
        socket

      # Match the paddle
      %{block: %{type: :paddle}, point: %{direction: :top} = point} ->
        socket
        |> assign(
          :ball,
          %{
            ball
            | x: point.x,
              y: point.y,
              dx: ball_dx_after_paddle(point.x, paddle.left, unit),
              dy: -ball.dy,
              left: point.x - ball.radius,
              top: point.y - ball.radius
          }
        )

      # Match every other brick + the paddle from the sides
      %{block: block, point: point} ->
        socket
        |> assign(:bricks, hide_brick(bricks, block.id))
        |> assign(
          :ball,
          %{
            ball
            | x: point.x,
              y: point.y,
              dx: collision_direction_x(ball.dx, point.direction),
              dy: collision_direction_y(ball.dy, point.direction),
              left: point.x - ball.radius,
              top: point.y - ball.radius
          }
        )
    end
  end

  defp build_closest(block, p, ball) do
    %{block: block, point: p, distance: Engine.compute_distance({p.x, p.y}, {ball.x, ball.y})}
  end

  defp hide_brick(blocks, id) do
    update_in(blocks, [Access.filter(&(&1.id == id and &1.type == :brick)), :visible], fn
      _ -> false
    end)
  end

  defp collision_direction_x(dx, direction) when direction in [:left, :right], do: -dx
  defp collision_direction_x(dx, _), do: dx

  defp collision_direction_y(dy, direction) when direction in [:top, :bottom], do: -dy
  defp collision_direction_y(dy, _), do: dy

  # Make the ball bounce off using the arkanoid style
  defp ball_dx_after_paddle(point_x, paddle_x, unit) do
    @ball_speed * (point_x - (paddle_x + @paddle_length * unit / 2)) / (@paddle_length * unit / 2)
  end

  defp check_lost(%{assigns: %{ball: ball, unit: unit}} = socket) do
    if ball.y + ball.dy + ball.radius >= (@board_rows - 1) * unit do
      socket
      |> assign(initial_state())
    else
      socket
    end
  end

  defp check_victory(%{assigns: %{bricks: bricks}} = socket) do
    bricks
    |> Enum.filter(&(&1.visible == true))
    |> Enum.count()
    |> case do
      0 ->
        state = initial_state()

        socket
        |> assign(state)
        |> assign(:blocks, Blocks.build_board(state.unit, state.unit))
        |> assign(:bricks, Blocks.build_bricks(state.unit, state.unit))

      _ ->
        socket
    end
  end

  # Handle keydown events
  defp on_input(socket, " " = _spacebar), do: start_game(socket)

  defp on_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in @left_keys,
       do: move_paddle(socket, :left)

  defp on_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in @right_keys,
       do: move_paddle(socket, :right)

  defp on_input(socket, _), do: socket

  # Handle keyup events
  defp on_stop_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in @left_keys,
       do: stop_paddle(socket, :left)

  defp on_stop_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in @right_keys,
       do: stop_paddle(socket, :right)

  defp on_stop_input(socket, _), do: socket

  # Start moving the ball up, in a random horizontal direction
  defp start_game(%{assigns: %{game_state: state, ball: ball}} = socket)
       when state in [:wait, :over] do
    socket
    |> assign(:game_state, :playing)
    |> assign(
      :ball,
      %{ball | dx: starting_dx(), dy: -ball.speed}
    )
  end

  defp start_game(socket), do: socket

  defp move_paddle(%{assigns: %{paddle: paddle}} = socket, direction) do
    if paddle.direction == direction do
      socket
    else
      socket
      |> assign(:paddle, %{paddle | direction: direction})
    end
  end

  defp stop_paddle(%{assigns: %{paddle: paddle}} = socket, direction) do
    if paddle.direction == direction do
      socket
      |> assign(:paddle, %{paddle | direction: :stationary})
    else
      socket
    end
  end

  defp advance_paddle(socket) do
    do_advance_paddle(socket, socket.assigns.paddle.direction)
  end

  defp do_advance_paddle(%{assigns: %{paddle: paddle, unit: unit}} = socket, :left) do
    new_left = max(unit, paddle.left - paddle.speed)

    socket
    |> assign(:paddle, %{paddle | left: new_left, right: paddle.right - (paddle.left - new_left)})
  end

  defp do_advance_paddle(%{assigns: %{paddle: paddle, unit: unit}} = socket, :right) do
    new_left = min(paddle.left + paddle.speed, unit * (@board_cols - paddle.length - 1))

    socket
    |> assign(:paddle, %{paddle | left: new_left, right: paddle.right + (new_left - paddle.left)})
  end

  defp do_advance_paddle(socket, :stationary), do: socket

  defp starting_dx(), do: @starting_angles |> Enum.random() |> :math.cos() |> Kernel.*(@ball_speed)
end
