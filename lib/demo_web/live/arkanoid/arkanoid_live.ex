defmodule DemoWeb.ArkanoidLive do
  use Phoenix.LiveView

  use DemoWeb.ArkanoidLive.Config

  alias DemoWeb.ArkanoidLive.Helpers
  alias DemoWeb.ArkanoidLive.Board
  alias DemoWeb.ArkanoidLive.Engine

  def render(assigns) do
    ~L"""
    <div class="game-container" phx-keydown="keydown" phx-keyup="keyup" phx-target="window">
      <div class="block ball"
          style="left: <%= @x %>px;
                top: <%= @y %>px;
                width: <%= @ball_width %>px;
                height: <%= @ball_width %>px;
      "></div>

      <div class="block paddle"
          style="left: <%= @paddle_x %>px;
            top: <%= @paddle_y %>px;
            width: <%= @width * @paddle_length %>px;
            height: <%= @width %>px;
      "></div>

      <%= for block <- @blocks, block.type in [:wall, :floor] do %>
        <div class="block <%= block.type %>"
            style="left: <%= block.x %>px;
                    top: <%= block.y %>px;
                    width: <%= block.width %>px;
                    height: <%= block.height %>px; %>;
        "></div>
      <% end %>

      <%= for brick <- @bricks, brick.visible == true do %>
        <div class="block brick"
            style="left: <%= brick.x %>px;
                    top: <%= brick.y %>px;
                    width: <%= brick.width %>px;
                    height: <%= brick.height %>px;
                    background: <%= Map.fetch!(brick, :color) %>;
        "></div>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    props = %{
      # game info
      game_state: :wait,
      tick: @tick,
      width: @width,
      height: @width,
      # paddle info (top left coordinates)
      paddle_x: Helpers.top_left_x(@paddle_x, @width),
      paddle_y: Helpers.top_left_y(@paddle_y, @width),
      paddle_length: @paddle_length,
      paddle_direction: :stationary,
      # ball info (initially placed at the middle of the paddle, one row above)
      # N.B: here we are using full coordinates, rather than scaled to the board
      ball_width: @ball_width,
      ball_radius: @ball_radius,
      x: Helpers.top_left_x(@ball_x, @width),
      y: Helpers.top_left_y(@ball_y, @width),
      dx: 0,
      dy: 0
    }

    socket =
      socket
      |> assign(props)
      |> assign(:blocks, Board.build_board(props.width, props.height))
      |> assign(:bricks, Board.build_bricks(props.width, props.height))
      |> advance_ball()

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
    |> brick_collision()
    |> paddle_collision()
  end

  defp game_loop(socket), do: socket

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, socket.assigns.tick)
    socket
  end

  defp advance_ball(socket) do
    %{x: x, y: y, dx: dx, dy: dy, width: width} = socket.assigns

    new_dx = ball_horizontal(x, dx, width)
    new_dy = ball_vertical(y, dy, width)

    socket
    |> assign(:x, x + new_dx)
    |> assign(:y, y + new_dy)
    |> assign(:dx, new_dx)
    |> assign(:dy, new_dy)
  end

  # TODO: This should be ((@board_cols - 1) * w) - 2 * ball_radius
  defp ball_horizontal(x, dx, w) when x + dx >= (@board_cols - 2) * w, do: -dx
  defp ball_horizontal(x, dx, w) when x + dx < w, do: -dx
  defp ball_horizontal(_x, dx, _), do: dx

  defp ball_vertical(y, dy, w) when y + dy >= (@board_rows - 1) * w, do: -dy
  defp ball_vertical(y, dy, w) when y + dy < w, do: -dy
  defp ball_vertical(_y, dy, _), do: dy

  # Compute the closest point of intersection (if any) between the ball and bricks
  defp brick_collision(
         %{assigns: %{bricks: bricks, ball_width: ball_width, dx: dx, dy: dy, ball_radius: radius}} =
           socket
       ) do
    # Use center coordinates
    x = socket.assigns.x + ball_width / 2
    y = socket.assigns.y + ball_width / 2

    bricks
    |> Enum.filter(& &1.visible)
    |> Enum.reduce(nil, fn brick, acc ->
      case {Engine.collision_point(x, y, dx, dy, radius, brick), acc} do
        {nil, _} ->
          acc

        {p, nil} ->
          build_closest(brick, p, x, y)

        {p, %{distance: distance}} ->
          new_distance = Engine.compute_distance({p.x, p.y}, {x, y})

          if new_distance < distance do
            build_closest(brick, p, x, y)
          else
            acc
          end
      end
    end)
    |> case do
      nil ->
        socket

      %{brick: brick, point: point} ->
        socket
        |> assign(:bricks, hide_brick(bricks, brick.id))
        |> assign(:x, point.x - ball_width / 2)
        |> assign(:y, point.y - ball_width / 2)
        |> assign(:dx, collision_direction_x(dx, point.direction))
        |> assign(:dy, collision_direction_y(dy, point.direction))
    end
  end

  defp build_closest(brick, p, ball_x, ball_y) do
    %{brick: brick, point: p, distance: Engine.compute_distance({p.x, p.y}, {ball_x, ball_y})}
  end

  defp hide_brick(bricks, id) do
    update_in(bricks, [Access.filter(&(&1.id == id)), :visible], fn _ -> false end)
  end

  defp collision_direction_x(dx, direction) when direction in [:left, :right], do: -dx
  defp collision_direction_x(dx, _), do: dx

  defp collision_direction_y(dy, direction) when direction in [:top, :bottom], do: -dy
  defp collision_direction_y(dy, _), do: dy

  # TODO: Improve this by giving top/bottom left/right coords to the paddle
  defp paddle_collision(
         %{
           assigns: %{
             dx: dx,
             dy: dy,
             width: w,
             paddle_x: paddle_x,
             paddle_y: paddle_y,
             ball_radius: radius,
             ball_width: ball_width
           }
         } = socket
       ) do
    # Use center coordinates
    x = socket.assigns.x + ball_width / 2
    y = socket.assigns.y + ball_width / 2

    paddle_rect = %{
      left: paddle_x,
      right: paddle_x + @paddle_length * w,
      top: paddle_y,
      bottom: paddle_y + w
    }

    case(Engine.collision_point(x, y, dx, dy, radius, paddle_rect)) do
      nil ->
        socket

      %{direction: :top} = point ->
        socket
        |> assign(:x, point.x - ball_width / 2)
        |> assign(:y, point.y - ball_width / 2)
        |> assign(:dx, ball_dx_after_paddle(point.x - ball_width / 2, paddle_x, w))
        |> assign(:dy, -dy)

      # This match is only needed for graphical consistency, since the game is already lost at this point
      point ->
        socket
        |> assign(:x, point.x - ball_width / 2)
        |> assign(:y, point.y - ball_width / 2)
        |> assign(:dx, -dx)
    end
  end

  defp ball_dx_after_paddle(x, paddle_x, w) do
    @ball_speed * (x - (paddle_x + @paddle_length * w / 2)) / (@paddle_length * w / 2)
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
  defp start_game(%{assigns: %{game_state: state}} = socket)
       when state in [:wait, :over] do
    socket
    |> assign(:dy, -@ball_speed)
    |> assign(:dx, Helpers.starting_x())
    |> assign(:game_state, :playing)
  end

  defp start_game(socket), do: socket

  defp move_paddle(socket, direction) do
    if socket.assigns.paddle_direction == direction do
      socket
    else
      socket
      |> assign(:paddle_direction, direction)
    end
  end

  defp stop_paddle(socket, direction) do
    if socket.assigns.paddle_direction == direction do
      socket
      |> assign(:paddle_direction, :stationary)
    else
      socket
    end
  end

  defp advance_paddle(socket) do
    do_advance_paddle(socket, socket.assigns.paddle_direction)
  end

  defp do_advance_paddle(socket, :left) do
    width = socket.assigns.width
    paddle_x = socket.assigns.paddle_x

    socket
    |> assign(:paddle_x, max(1 * width, paddle_x - @paddle_speed))
  end

  defp do_advance_paddle(socket, :right) do
    width = socket.assigns.width
    paddle_x = socket.assigns.paddle_x

    socket
    |> assign(:paddle_x, min(paddle_x + @paddle_speed, width * (@board_cols - @paddle_length - 1)))
  end

  defp do_advance_paddle(socket, :stationary), do: socket
end
