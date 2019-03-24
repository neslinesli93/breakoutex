defmodule DemoWeb.ArkanoidLive do
  use Phoenix.LiveView

  @tick 100
  @width 10

  @blocks_colors ~w(r b g o p y)
  @block_length 3

  # x coordinate of the left corner of the platform
  @platform_x 10
  @platform_y 15
  @platform_length 5

  """
  Syntax:
  - X are the walls
  - D is the floor
  - r, b, g, o, p, y are the colors of the different blocks
  """

  # TODO: Remove S and B
  @board [
    ~w(X X X X X X X X X X X X X X X X X X X X X X X X X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
    ~w(X 0 0 0 r r r r r r r r r r r r r r r r r r 0 0 X),
    ~w(X 0 0 0 b b b b b b b b b b b b b b b b b b 0 0 X),
    ~w(X 0 0 0 g g g g g g g g g g g g g g g g g g 0 0 X),
    ~w(X 0 0 0 o o o o o o o o o o o o o o o o o o 0 0 X),
    ~w(X 0 0 0 p p p p p p p p p p p p p p p p p p 0 0 X),
    ~w(X 0 0 0 y y y y y y y y y y y y y y y y y y 0 0 X),
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
      <%= for x <- @platform do %>
        <div class="block platform"
            style="left: <%= x_coord(x, @width) %>px;
                  top: <%= y_coord(@platform_y, @width) %>px;
                  width: <%= @width %>px;
                  height: <%= @width %>px;
        "></div>
      <% end %>
      <%= for {_, block} <- @blocks, block.type !== :empty do %>
        <div class="block <%= block.type %>"
            style="left: <%= block.x %>px;
                    top: <%= block.y %>px;
                    width: <%= block.width %>px;
                    height: <%= block.width %>px;
                    background: <%= Map.get(block, :color, "") %>;
        "></div>
      <% end %>
    </div>
    """
  end

  def mount(_session, socket) do
    props = %{
      game_state: :wait,
      width: @width,
      tick: @tick,
      platform: [],
      platform_y: @platform_y,
      # ball info (initially placed at the middle of the platform, one row above)
      heading: :stationary,
      row: 12,
      col: 14,
      x: nil,
      y: nil
    }

    socket =
      socket
      |> assign(props)
      |> build_board()
      |> build_platform()
      |> advance_ball()

    if connected?(socket) do
      {:ok, schedule_tick(socket)}
    else
      {:ok, socket}
    end
  end

  def handle_info(:tick, socket) do
    # new_socket =
    #   socket
    #   |> game_loop()
    #   |> schedule_tick()

    # {:noreply, new_socket}

    {:noreply, socket}
  end

  def handle_event("keydown", key, socket) do
    IO.inspect("received keydown event")
    {:noreply, on_input(socket, key)}
  end

  # The key " " corresponds to spacebar
  defp on_input(%{assigns: %{game_state: :wait}} = socket, " "), do: start_game(socket)
  defp on_input(socket, key) when key in ["ArrowLeft", "a", "A"], do: move_plat(socket, :left)
  defp on_input(socket, key) when key in ["ArrowRight", "d", "D"], do: move_plat(socket, :right)
  defp on_input(socket, _), do: socket

  defp start_game(socket) do
    heading = Enum.random([:left, :right])
    # TODO: Start moving the ball on the given direction using advance_ball

    socket
  end

  defp move_plat(socket, heading) do
    update(socket, :platform, &platform_position(&1, heading))
  end

  # Don't go across boundaries with platform
  defp platform_position([val | _tail] = platform, :left) when val - 1 >= 1 do
    Enum.map(platform, &(&1 - 1))
  end

  defp platform_position([val | _tail] = platform, :right) do
    case val + @platform_length < @board_cols - 1 do
      true -> Enum.map(platform, &(&1 + 1))
      false -> platform
    end
  end

  defp platform_position(platform, _), do: platform

  def game_loop(socket) do
    socket
    |> advance_ball()
  end

  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, socket.assigns.tick)
    socket
  end

  defp build_platform(socket) do
    platform =
      @platform_x..(@platform_x + @platform_length - 1)
      |> Enum.to_list()

    assign(socket, :platform, platform)
  end

  defp x_coord(x, width), do: x * width
  defp y_coord(y, width), do: y * width

  defp build_board(socket) do
    width = socket.assigns.width

    {_, blocks} =
      Enum.reduce(@board, {0, %{}}, fn row, {y_idx, acc} ->
        {_, blocks} =
          Enum.reduce(row, {0, acc}, fn
            "X", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {y_idx, x_idx}, wall(x_idx, y_idx, width))}

            "0", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {y_idx, x_idx}, empty(x_idx, y_idx, width))}

            "D", {x_idx, acc} ->
              {x_idx + 1, Map.put(acc, {y_idx, x_idx}, floor(x_idx, y_idx, width))}

            b, {x_idx, acc} when b in @blocks_colors ->
              {x_idx + 1, Map.put(acc, {y_idx, x_idx}, block(b, x_idx, y_idx, width))}
          end)

        {y_idx + 1, blocks}
      end)

    # IO.inspect(blocks, label: "blocks", limit: :infinity)

    assign(socket, :blocks, blocks)
  end

  defp wall(x_idx, y_idx, width) do
    %{type: :wall, x: x_idx * width, y: y_idx * width, width: width}
  end

  defp floor(x_idx, y_idx, width) do
    %{type: :floor, x: x_idx * width, y: y_idx * width, width: width}
  end

  defp empty(x_idx, y_idx, width) do
    %{type: :empty, x: x_idx * width, y: y_idx * width, width: width}
  end

  # ATM, block generation depends both on map size and block size, which are hardcoded
  defp block(color, x_idx, y_idx, width) do
    case rem(x_idx, @block_length) do
      1 ->
        %{
          type: :block_head,
          color: get_color(color),
          x: x_idx * width,
          y: y_idx * width,
          width: width
        }

      2 ->
        %{
          type: :block_body,
          color: get_color(color),
          x: x_idx * width,
          y: y_idx * width,
          width: width
        }

      0 ->
        %{
          type: :block_tail,
          color: get_color(color),
          x: x_idx * width,
          y: y_idx * width,
          width: width
        }
    end
  end

  defp get_color("r"), do: "red"
  defp get_color("b"), do: "blue"
  defp get_color("g"), do: "green"
  defp get_color("y"), do: "yellow"
  defp get_color("o"), do: "orange"
  defp get_color("p"), do: "purple"

  defp advance_ball(socket) do
    %{width: width, heading: heading, blocks: blocks} = socket.assigns
    col_before = socket.assigns.col
    row_before = socket.assigns.row
    maybe_row = row(row_before, heading)
    maybe_col = col(col_before, heading)

    {row, col} =
      case Map.fetch!(blocks, {maybe_row, maybe_col}).type do
        :wall -> {row_before, col_before}
        :empty -> {maybe_row, maybe_col}
      end

    socket
    |> assign(:row, row)
    |> assign(:col, col)
    |> assign(:x, col * width)
    |> assign(:y, row * width)
  end

  # Basic collision detection
  defp col(val, :left) when val - 1 >= 1, do: val - 1
  defp col(val, :right) when val + 1 < @board_cols - 1, do: val + 1
  defp col(val, _), do: val

  defp row(val, :up) when val - 1 >= 1, do: val - 1
  defp row(val, :down) when val + 1 < @board_rows - 1, do: val + 1
  defp row(val, _), do: val
end
