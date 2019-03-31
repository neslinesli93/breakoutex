defmodule DemoWeb.ArkanoidLive do
  use Phoenix.LiveView

  use DemoWeb.ArkanoidLive.Config

  alias DemoWeb.ArkanoidLive.Helpers
  alias DemoWeb.ArkanoidLive.Board
  alias DemoWeb.ArkanoidLive.Engine

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

      <%= for block <- @obstacles, block.type == :brick and block.visible == true do %>
        <div class="block brick"
            style="left: <%= block.left %>px;
                    top: <%= block.top %>px;
                    width: <%= block.width %>px;
                    height: <%= block.height %>px;
                    background: <%= Map.fetch!(block, :color) %>; "></div>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    state = initial_state()

    socket =
      socket
      |> assign(state)
      |> assign(:blocks, Board.build_board(state.unit, state.unit))
      |> assign(:obstacles, Board.build_obstacles(state.unit, state.unit))

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
    |> obstacles_collision()
    |> paddle_collision()
    |> check_gameover()
  end

  defp game_loop(socket), do: socket

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, socket.assigns.tick)
    socket
  end

  defp advance_ball(%{assigns: %{ball: ball}} = socket) do
    socket
    |> assign(
      :ball,
      ball
      |> update_in([:x], &(&1 + ball.dx))
      |> update_in([:left], &(&1 + ball.dx))
      |> update_in([:y], &(&1 + ball.dy))
      |> update_in([:top], &(&1 + ball.dy))
    )
  end

  # Compute the closest point of intersection, if any, between the ball and obstacles (bricks, walls)
  defp obstacles_collision(%{assigns: %{obstacles: obstacles, ball: ball}} = socket) do
    obstacles
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

      %{block: block, point: point} ->
        socket
        |> assign(:obstacles, hide_brick(obstacles, block.id))
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

  defp paddle_collision(%{assigns: %{ball: ball, paddle: paddle, unit: unit}} = socket) do
    Engine.collision_point(ball.x, ball.y, ball.dx, ball.dy, ball.radius, paddle)
    |> case do
      nil ->
        socket

      %{direction: :top} = point ->
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

      # This match is only needed for graphical consistency, since the game is already lost at this point
      point ->
        socket
        |> assign(
          :ball,
          %{
            ball
            | x: point.x,
              y: point.y,
              dx: -ball.dx,
              left: point.x - ball.radius,
              top: point.y - ball.radius
          }
        )
    end
  end

  # Make the ball bounce off using the arkanoid style
  defp ball_dx_after_paddle(point_x, paddle_x, unit) do
    @ball_speed * (point_x - (paddle_x + @paddle_length * unit / 2)) / (@paddle_length * unit / 2)
  end

  defp check_gameover(%{assigns: %{ball: ball, unit: unit}} = socket) do
    if ball.y >= @board_rows * unit do
      state = initial_state()

      socket
      |> assign(state)
      |> assign(:blocks, Board.build_board(state.unit, state.unit))
      |> assign(:obstacles, Board.build_obstacles(state.unit, state.unit))
    else
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
      %{ball | dx: Helpers.starting_dx(), dy: -ball.speed}
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
end
