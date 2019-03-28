defmodule DemoWeb.ArkanoidLive do
  use Phoenix.LiveView

  # See https://codeincomplete.com/posts/collision-detection-in-breakout/ for a detailed explanation
  # of game mechanics

  @tick 32
  @width 20

  @blocks_colors ~w(r b g o p y)
  @block_length 3

  # x coordinate of the left corner of the paddle
  @paddle_x 10
  @paddle_y 18
  @paddle_length 5
  @paddle_speed 0.8

  @ball_speed 0.3

  # Syntax:
  # - X are the walls
  # - D is the floor
  # - r, b, g, o, p, y are the colors of the different blocks
  @board [
    ~w(X X X X X X X X X X X X X X X X X X X X X X X X X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 r 0 0 r 0 0 r 0 0 r 0 0 r 0 0 r 0 0 0 0 X),
    ~w(X 0 0 0 b 0 0 b 0 0 b 0 0 b 0 0 b 0 0 b 0 0 0 0 X),
    ~w(X 0 0 0 g 0 0 g 0 0 g 0 0 g 0 0 g 0 0 g 0 0 0 0 X),
    ~w(X 0 0 0 o 0 0 o 0 0 o 0 0 o 0 0 o 0 0 o 0 0 0 0 X),
    ~w(X 0 0 0 p 0 0 p 0 0 p 0 0 p 0 0 p 0 0 p 0 0 0 0 X),
    ~w(X 0 0 0 y 0 0 y 0 0 y 0 0 y 0 0 y 0 0 y 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(D D D D D D D D D D D D D D D D D D D D D D D D D)
  ]
  @board_rows length(@board)
  @board_cols length(hd(@board))

  def render(assigns) do
    ~L"""
    <div class="game-container" phx-keydown="keydown" phx-target="window">
      <div class="block ball"
          style="left: <%= x_coord(@x, @width) %>px;
                top: <%= y_coord(@y, @width) %>px;
                width: <%= @ball_width %>px;
                height: <%= @ball_width %>px;
      "></div>

      <div class="block paddle"
          style="left: <%= x_coord(@paddle_x, @width) %>px;
            top: <%= y_coord(@paddle_y, @width) %>px;
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

      <%= for block <- @obstacles, block.visible == true do %>
        <div class="block <%= block.type %>"
            style="left: <%= block.x %>px;
                    top: <%= block.y %>px;
                    width: <%= block.width %>px;
                    height: <%= block.height %>px;
                    background: <%= Map.get(block, :color, "") %>;
        "></div>
      <% end %>
    </div>
    """
  end

  # TODO: platform is useless as an array, we can remove it and only keep the head
  def mount(_session, socket) do
    props = %{
      game_state: :wait,
      width: @width,
      tick: @tick,
      paddle_x: @paddle_x,
      paddle_y: @paddle_y,
      paddle_length: @paddle_length,
      # ball info (initially placed at the middle of the paddle, one row above)
      x: 12,
      y: 17,
      dx: 0,
      dy: 0,
      ball_width: @width / 1.2
    }

    socket =
      socket
      |> assign(props)
      |> build_board()
      |> build_obstacles()
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

  def game_loop(socket) do
    socket
    |> advance_ball()
    |> obstacle_collision()
    |> paddle_collision()
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, socket.assigns.tick)
    socket
  end

  defp advance_ball(socket) do
    %{x: x, y: y, dx: dx, dy: dy} = socket.assigns

    new_dx = ball_horizontal(x, dx)
    new_dy = ball_vertical(y, dy)

    socket
    |> assign(:x, x + new_dx)
    |> assign(:y, y + new_dy)
    |> assign(:dx, new_dx)
    |> assign(:dy, new_dy)
  end

  defp ball_horizontal(x, dx) when x + dx >= @board_cols - 1, do: -dx
  defp ball_horizontal(x, dx) when x + dx < 1, do: -dx
  defp ball_horizontal(_x, dx), do: dx

  defp ball_vertical(y, dy) when y + dy >= @board_rows - 1, do: -dy
  defp ball_vertical(y, dy) when y + dy < 1, do: -dy
  defp ball_vertical(_y, dy), do: dy

  defp obstacle_collision(%{assigns: %{obstacles: obstacles, width: width, dy: dy}} = socket) do
    x = x_coord(socket.assigns.x, width)
    y = x_coord(socket.assigns.y, width)

    obstacles
    |> Enum.find_index(fn
      %{visible: true} = b ->
        x > b.x and x < b.x + b.width and y > b.y and y <= b.y + b.height

      _ ->
        false
    end)
    |> case do
      nil ->
        socket

      index ->
        socket
        |> assign(:obstacles, update_in(obstacles, [Access.at(index), :visible], &(!&1)))
        |> assign(:dy, -dy)
    end
  end

  defp paddle_collision(%{assigns: %{x: x, y: y, dx: dx, dy: dy, paddle_x: paddle_x}} = socket) do
    if y + dy >= @paddle_y and (x >= paddle_x and x <= paddle_x + @paddle_length) do
      assign(socket, :dy, -dy)
    else
      socket
    end
  end

  defp on_input(socket, " " = _spacebar), do: start_game(socket)

  defp on_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in ["ArrowLeft", "a", "A"],
       do: move_paddle(socket, :left)

  defp on_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in ["ArrowRight", "d", "D"],
       do: move_paddle(socket, :right)

  defp on_input(socket, _), do: socket

  # Start moving the ball up, in a random horizontal direction
  defp start_game(%{assigns: %{game_state: state}} = socket) when state in [:wait, :over] do
    socket
    |> assign(:dy, -@ball_speed)
    |> assign(:dx, Enum.random([-@ball_speed, +@ball_speed]))
    |> assign(:game_state, :playing)
    |> assign(:tt, get_tt())
  end

  defp start_game(socket), do: socket

  defp move_paddle(socket, :left) do
    now = get_tt()
    tt = socket.assigns.tt
    paddle_x = socket.assigns.paddle_x

    dx =
      case now - tt < 100 do
        true -> @paddle_speed * 2
        false -> @paddle_speed
      end

    x = max(1, paddle_x - dx)

    socket
    |> assign(:paddle_x, x)
    |> assign(:tt, now)
  end

  defp move_paddle(socket, :right) do
    now = get_tt()
    tt = socket.assigns.tt
    paddle_x = socket.assigns.paddle_x

    dx =
      case now - tt < 100 do
        true -> @paddle_speed * 2
        false -> @paddle_speed
      end

    x = min(paddle_x + dx, @board_cols - @paddle_length - 1)

    socket
    |> assign(:paddle_x, x)
    |> assign(:tt, now)
  end

  # defp move_plat(%{assigns: %{game_state: :playing}} = socket, heading),
  #   do: update(socket, :paddle, &paddle_position(&1, heading))

  # defp move_plat(socket, _), do: socket

  # # Don't go across boundaries with paddle
  # defp paddle_position([val | _tail] = paddle, :left) when val - 1 >= 1 do
  #   Enum.map(paddle, &(&1 - 1))
  # end

  # defp paddle_position([val | _tail] = paddle, :right) do
  #   case val + @paddle_length < @board_cols - 1 do
  #     true -> Enum.map(paddle, &(&1 + 1))
  #     false -> paddle
  #   end
  # end

  # defp paddle_position(paddle, _), do: paddle

  # defp build_paddle(socket) do
  #   paddle =
  #     @paddle_x..(@paddle_x + @paddle_length - 1)
  #     |> Enum.to_list()

  #   assign(socket, :paddle, paddle)
  # end

  defp build_board(socket) do
    width = socket.assigns.width

    {_, blocks} =
      Enum.reduce(@board, {0, []}, fn row, {y_idx, acc} ->
        {_, blocks} =
          Enum.reduce(row, {0, acc}, fn
            "X", {x_idx, acc} ->
              {x_idx + 1, [wall(x_idx, y_idx, width) | acc]}

            "0", {x_idx, acc} ->
              {x_idx + 1, [empty(x_idx, y_idx, width) | acc]}

            "D", {x_idx, acc} ->
              {x_idx + 1, [floor(x_idx, y_idx, width) | acc]}

            b, {x_idx, acc} when b in @blocks_colors ->
              {x_idx + 1, [block(b, x_idx, y_idx, width) | acc]}
          end)

        {y_idx + 1, blocks}
      end)

    assign(socket, :blocks, blocks)
  end

  defp wall(x_idx, y_idx, width) do
    %{type: :wall, x: x_idx * width, y: y_idx * width, width: width, height: width}
  end

  defp floor(x_idx, y_idx, width) do
    %{type: :floor, x: x_idx * width, y: y_idx * width, width: width, height: width}
  end

  defp empty(x_idx, y_idx, width) do
    %{type: :empty, x: x_idx * width, y: y_idx * width, width: width, height: width}
  end

  defp block(color, x_idx, y_idx, width) do
    %{
      type: :obstacle,
      color: get_color(color),
      x: x_idx * width,
      y: y_idx * width,
      width: width * @block_length,
      height: width,
      visible: true
    }
  end

  defp build_obstacles(%{assigns: %{blocks: blocks}} = socket) do
    socket
    |> assign(:obstacles, Enum.filter(blocks, &(&1.type == :obstacle)))
  end

  defp get_tt(), do: :os.system_time(:milli_seconds)

  defp get_color("r"), do: "red"
  defp get_color("b"), do: "blue"
  defp get_color("g"), do: "green"
  defp get_color("y"), do: "yellow"
  defp get_color("o"), do: "orange"
  defp get_color("p"), do: "purple"

  defp x_coord(x, width), do: x * width
  defp y_coord(y, width), do: y * width
end
