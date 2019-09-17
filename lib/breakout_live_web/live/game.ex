defmodule BreakoutLiveWeb.Live.Game do
  @moduledoc """
  Main module, contains the entry point for the live view socket and
  all the game logic
  """

  use Phoenix.LiveView
  use BreakoutLiveWeb.Live.Config

  alias BreakoutLiveWeb.Live.{Blocks, Engine}

  def render(assigns) do
    BreakoutLiveWeb.BreakoutView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    state = initial_state()

    socket =
      socket
      |> assign(state)
      |> assign(:blocks, Blocks.build_board(state.level, state.unit, state.unit))
      |> assign(:bricks, Blocks.build_bricks(state.level, state.unit, state.unit))

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

    assign(
      socket,
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

  defp ball_vertical(y, dy, r, u) when y + dy + r > @board_rows * u, do: -dy
  defp ball_vertical(y, dy, r, u) when y + dy - r < u, do: -dy
  defp ball_vertical(_y, dy, _r, _u), do: dy

  # Compute the closest point of intersection, if any, between the ball and obstacles (bricks and paddle)
  defp check_collision(
         %{assigns: %{bricks: bricks, ball: ball, paddle: paddle, unit: unit}} = socket
       ) do
    [paddle | bricks]
    |> Enum.filter(& &1.visible)
    |> Enum.reduce(nil, fn block, acc ->
      case {Engine.collision_point(ball.x, ball.y, ball.dx, ball.dy, ball.radius, block), acc} do
        {nil, _} ->
          acc

        {p, nil} ->
          build_closest(block, p, ball)

        {p, %{distance: distance}} ->
          maybe_build_closest(block, acc, p, ball, distance)
      end
    end)
    |> case do
      nil ->
        socket

      # Match the paddle
      %{block: %{type: :paddle}, point: %{direction: :top} = point} ->
        assign(
          socket,
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

      # Match every other brick OR the paddle from the sides
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

  defp maybe_build_closest(new_block, curr_block, p, ball, curr_distance) do
    new_distance = Engine.compute_distance({p.x, p.y}, {ball.x, ball.y})

    if new_distance < curr_distance do
      build_closest(new_block, p, ball)
    else
      curr_block
    end
  end

  defp build_closest(block, p, ball) do
    %{block: block, point: p, distance: Engine.compute_distance({p.x, p.y}, {ball.x, ball.y})}
  end

  defp hide_brick(blocks, id) do
    Enum.map(blocks, fn
      %{id: ^id, type: :brick} = block -> %{block | visible: false}
      b -> b
    end)
  end

  defp collision_direction_x(dx, direction) when direction in [:left, :right], do: -dx
  defp collision_direction_x(dx, _), do: dx

  defp collision_direction_y(dy, direction) when direction in [:top, :bottom], do: -dy
  defp collision_direction_y(dy, _), do: dy

  # Make the ball bounce off using the Breakout style
  defp ball_dx_after_paddle(point_x, paddle_x, unit) do
    @ball_speed * (point_x - (paddle_x + @paddle_length * unit / 2)) / (@paddle_length * unit / 2)
  end

  defp check_lost(%{assigns: %{ball: ball, unit: unit, lost_lives: lost_lives}} = socket) do
    if ball.y + ball.dy + ball.radius >= @board_rows * unit do
      socket
      |> assign(:game_state, :wait)
      |> assign(:paddle, initial_paddle_state())
      |> assign(:ball, initial_ball_state())
      |> assign(:lost_lives, lost_lives + 1)
    else
      socket
    end
  end

  defp check_victory(%{assigns: %{bricks: bricks, level: level}} = socket) do
    bricks
    |> Enum.filter(&(&1.visible == true))
    |> Enum.count()
    |> case do
      0 ->
        socket
        |> assign(:level, level + 1)
        |> next_level()

      _ ->
        socket
    end
  end

  defp next_level(%{assigns: %{level: level, unit: unit}} = socket) when level < @levels_no do
    socket
    |> assign(:game_state, :wait)
    |> assign(:paddle, initial_paddle_state())
    |> assign(:ball, initial_ball_state())
    |> assign(:blocks, Blocks.build_board(level, unit, unit))
    |> assign(:bricks, Blocks.build_bricks(level, unit, unit))
  end

  defp next_level(%{assigns: %{ball: ball}} = socket) do
    socket
    |> assign(:game_state, :finish)
    |> assign(:level, @levels_no - 1)
    |> assign(:ball, %{ball | dx: 0, dy: 0})
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

  defp start_game(%{assigns: %{game_state: :welcome}} = socket) do
    assign(socket, :game_state, :wait)
  end

  # Start moving the ball up, in a random horizontal direction
  defp start_game(%{assigns: %{game_state: :wait, ball: ball}} = socket) do
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
      assign(socket, :paddle, %{paddle | direction: direction})
    end
  end

  defp stop_paddle(%{assigns: %{paddle: paddle}} = socket, direction) do
    if paddle.direction == direction do
      assign(socket, :paddle, %{paddle | direction: :stationary})
    else
      socket
    end
  end

  defp advance_paddle(socket) do
    do_advance_paddle(socket, socket.assigns.paddle.direction)
  end

  defp do_advance_paddle(%{assigns: %{paddle: paddle, unit: unit}} = socket, :left) do
    new_left = max(unit, paddle.left - paddle.speed)

    assign(socket, :paddle, %{
      paddle
      | left: new_left,
        right: paddle.right - (paddle.left - new_left)
    })
  end

  defp do_advance_paddle(%{assigns: %{paddle: paddle, unit: unit}} = socket, :right) do
    new_left = min(paddle.left + paddle.speed, unit * (@board_cols - paddle.length - 1))

    assign(socket, :paddle, %{
      paddle
      | left: new_left,
        right: paddle.right + (new_left - paddle.left)
    })
  end

  defp do_advance_paddle(socket, :stationary), do: socket

  defp starting_dx(), do: @starting_angles |> Enum.random() |> :math.cos() |> Kernel.*(@ball_speed)
end
