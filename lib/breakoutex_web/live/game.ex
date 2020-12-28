defmodule BreakoutexWeb.Live.Game do
  @moduledoc """
  Main module, contains the entry point for the live view socket and
  all the game logic
  """

  use Phoenix.LiveView
  use BreakoutexWeb.Live.Config

  alias Phoenix.LiveView.Socket
  alias BreakoutexWeb.Live.{Blocks, Engine}
  alias BreakoutexWeb.Presence
  alias Breakoutex.PubSub

  @presence "breakout:presence"

  @type intersection_point :: %{
          block: paddle() | brick(),
          point: Engine.hitpoint(),
          distance: number()
        }

  def render(assigns) do
    BreakoutexWeb.GameView.render("index.html", assigns)
  end

  @spec mount(map() | :not_mounted_at_router, map(), Socket.t()) :: {:ok, Socket.t()}
  def mount(_params, _session, socket) do
    current_user_id = Map.get(socket.assigns, :current_user_id, "user_" <> Integer.to_string(System.os_time(:second)))

    if connected?(socket) do
      {:ok, _} = Presence.track(self(), @presence, current_user_id , %{
        name: "No name yet",
        joined_at: :os.system_time(:seconds),
        level: 1,
        points: 0
      })

      Phoenix.PubSub.subscribe(PubSub, @presence)
    end

    state = initial_state()
    socket =
      socket
      |> assign(state)
      |> assign(:current_user_id, current_user_id)
      |> assign(:users, %{})
      |> handle_joins(Presence.list(@presence))
      |> assign(:blocks, Blocks.build_board(state.level, state.unit, state.unit))
      |> assign(:bricks, Blocks.build_bricks(state.level, state.unit, state.unit))

    if connected?(socket) do
      {:ok, schedule_tick(socket)}
    else
      {:ok, socket}
    end
  end

  @spec handle_info(atom(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_info(:tick, socket) do
    new_socket =
      socket
      |> game_loop()
      |> schedule_tick()

    {:noreply, new_socket}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  @spec handle_event(String.t(), map(), Socket.t()) :: {:noreply, Socket.t()}
  def handle_event("keydown", %{"key" => key}, socket) do
    {:noreply, on_input(socket, key)}
  end

  def handle_event("keyup", %{"key" => key}, socket) do
    {:noreply, on_stop_input(socket, key)}
  end

  @spec game_loop(Socket.t()) :: Socket.t()
  defp game_loop(%{assigns: %{game_state: :playing}} = socket) do
    socket
    |> advance_paddle()
    |> advance_ball()
    |> check_collision()
    |> check_lost()
    |> check_victory()
  end

  defp game_loop(socket), do: socket

  @spec schedule_tick(Socket.t()) :: Socket.t()
  defp schedule_tick(socket) do
    Process.send_after(self(), :tick, socket.assigns.tick)
    socket
  end

  @spec advance_paddle(Socket.t()) :: Socket.t()
  defp advance_paddle(%{assigns: %{paddle: paddle, unit: unit}} = socket) do
    case paddle.direction do
      :left -> assign(socket, :paddle, move_paddle_left(paddle, unit))
      :right -> assign(socket, :paddle, move_paddle_right(paddle, unit))
      :stationary -> socket
    end
  end

  @spec move_paddle_left(paddle(), number()) :: paddle()
  defp move_paddle_left(paddle, unit) do
    new_left = max(unit, paddle.left - paddle.speed)

    %{paddle | left: new_left, right: paddle.right - (paddle.left - new_left)}
  end

  @spec move_paddle_right(paddle(), number()) :: paddle()
  defp move_paddle_right(paddle, unit) do
    new_left = min(paddle.left + paddle.speed, unit * (@board_cols - paddle.length - 1))

    %{paddle | left: new_left, right: paddle.right + (new_left - paddle.left)}
  end

  @spec advance_ball(Socket.t()) :: Socket.t()
  defp advance_ball(%{assigns: %{ball: ball, unit: unit}} = socket) do
    new_dx = ball_horizontal(ball.x, ball.dx, ball.radius, unit)
    new_dy = ball_vertical(ball.y, ball.dy, ball.radius, unit)

    assign(
      socket,
      :ball,
      %{ball | dx: new_dx, dy: new_dy}
      |> update_in([:x], &(&1 + new_dx))
      |> update_in([:y], &(&1 + new_dy))
    )
  end

  @spec ball_horizontal(number(), number(), number(), number()) :: number()
  defp ball_horizontal(x, dx, r, u) when x + dx + r >= (@board_cols - 1) * u, do: -dx
  defp ball_horizontal(x, dx, r, u) when x + dx - r < u, do: -dx
  defp ball_horizontal(_x, dx, _r, _u), do: dx

  @spec ball_vertical(number(), number(), number(), number()) :: number()
  defp ball_vertical(y, dy, r, u) when y + dy + r > @board_rows * u, do: -dy
  defp ball_vertical(y, dy, r, u) when y + dy - r < u, do: -dy
  defp ball_vertical(_y, dy, _r, _u), do: dy

  # Compute the closest point of intersection, if any, between the ball and obstacles (bricks and paddle)
  @spec check_collision(Socket.t()) :: Socket.t()
  defp check_collision(
         %{assigns: %{bricks: bricks, ball: ball, paddle: paddle, unit: unit, score: score, multiplier: multiplier}} =
           socket
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
        socket
        |> assign(
          :ball,
          %{
            ball
            | x: point.x,
              y: point.y,
              dx: ball_dx_after_paddle(point.x, paddle.left, unit),
              dy: -ball.dy
          }
        )
        |> assign(:multiplier, @starting_multiplier)

      # Match every other brick OR the paddle from the sides
      %{block: block, point: point} ->
        new_bricks = hide_brick(bricks, block.id)
        hit_bricks = count_hidden_bricks(new_bricks) - count_hidden_bricks(bricks)
        %{multiplier: new_multiplier, score: new_score} = handle_hit_bricks(hit_bricks, score, multiplier)

        socket
        |> assign(:bricks, new_bricks)
        |> update_player_points(new_score)
        |> assign(:multiplier, new_multiplier)
        |> assign(
          :ball,
          %{
            ball
            | x: point.x,
              y: point.y,
              dx: collision_direction_x(ball.dx, point.direction),
              dy: collision_direction_y(ball.dy, point.direction)
          }
        )
    end
  end

  defp handle_hit_bricks(0, score, multiplier) do
    %{score: score, multiplier: multiplier}
  end

  defp handle_hit_bricks(hits, score, multiplier) do
    handle_hit_bricks(hits - 1, add_to_score(score, multiplier), multiplier + 1)
  end

  @spec count_hidden_bricks([paddle() | brick()]) :: Integer.t()
  defp count_hidden_bricks(blocks) do
    Enum.reduce(blocks, 0, fn
      %{visible: false, type: :brick}, acc ->
        acc + 1

      _, acc ->
        acc
    end)
  end

  @spec maybe_build_closest(
          paddle() | brick(),
          intersection_point(),
          Engine.hitpoint(),
          ball(),
          number()
        ) ::
          intersection_point()
  defp maybe_build_closest(new_block, curr_intersection, p, ball, curr_distance) do
    new_distance = Engine.compute_distance({p.x, p.y}, {ball.x, ball.y})

    if new_distance < curr_distance do
      build_closest(new_block, p, ball)
    else
      curr_intersection
    end
  end

  @spec build_closest(paddle() | brick(), Engine.hitpoint(), ball()) :: intersection_point()
  defp build_closest(block, p, ball) do
    %{block: block, point: p, distance: Engine.compute_distance({p.x, p.y}, {ball.x, ball.y})}
  end

  @spec hide_brick([paddle() | brick()], String.t()) :: [paddle() | brick()]
  defp hide_brick(blocks, id) do
    Enum.map(blocks, fn
      %{id: ^id, type: :brick} = block ->
        %{block | visible: false}

      b ->
        b
    end)
  end

  @spec add_to_score(Integer.t(), Integer.t()) :: Integer.t()
  defp add_to_score(score, multiplier) do
    score + @points_for_brick * multiplier
  end

  @spec collision_direction_x(number(), Engine.direction()) :: number()
  defp collision_direction_x(dx, direction) when direction in [:left, :right], do: -dx
  defp collision_direction_x(dx, _), do: dx

  @spec collision_direction_y(number(), Engine.direction()) :: number()
  defp collision_direction_y(dy, direction) when direction in [:top, :bottom], do: -dy
  defp collision_direction_y(dy, _), do: dy

  # Make the ball bounce off using the Breakoutex style
  @spec ball_dx_after_paddle(number(), number(), number()) :: number()
  defp ball_dx_after_paddle(point_x, paddle_x, unit) do
    @ball_speed * (point_x - (paddle_x + @paddle_length * unit / 2)) / (@paddle_length * unit / 2)
  end

  @spec check_lost(Socket.t()) :: Socket.t()
  defp check_lost(%{assigns: %{ball: ball, unit: unit, lost_lives: lost_lives, score: score}} = socket) do
    if ball.y + ball.dy + ball.radius >= @board_rows * unit do
      socket
      |> assign(:game_state, :wait)
      |> assign(:paddle, initial_paddle_state())
      |> assign(:ball, initial_ball_state())
      |> assign(:lost_lives, lost_lives + 1)
      |> update_player_points(score - @points_subtracted_on_lost_life)
      |> assign(:multiplier, @starting_multiplier)
    else
      socket
    end
  end

  @spec check_victory(Socket.t()) :: Socket.t()
  defp check_victory(%{assigns: %{bricks: bricks, level: level}} = socket) do
    bricks
    |> Enum.filter(&(&1.visible == true))
    |> Enum.count()
    |> case do
      0 ->
        socket
        |> update_player_level(level + 1)
        |> assign(:secret_message, Enum.at(@levels, level + 1) |> Map.get(:message))
        |> next_level()

      _ ->
        socket
    end
  end

  @spec next_level(Socket.t()) :: Socket.t()
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
    |> update_player_level(@levels_no - 1)
    |> assign(:ball, %{ball | dx: 0, dy: 0})
  end

  # Handle keydown events
  @spec on_input(Socket.t(), String.t()) :: Socket.t()
  defp on_input(%{assigns: %{game_state: :name}} = socket, key) do
    cond do
      String.match?(key, ~r/\A\p{L}\p{M}*\z/u) ->
        socket
        |> assign(:player_name, socket.assigns.player_name <> key)

      key in @backspace ->
        name =
          if String.length(socket.assigns.player_name) > 0 do
            socket.assigns.player_name
            |> String.reverse()
            |> String.graphemes()
            |> tl()
            |> List.to_string()
            |> String.reverse()
          else
            socket.assigns.player_name
          end

        socket
        |> assign(:player_name, name)

      key in @return ->
        update_player_name(socket)
        |> start_game

      true ->
        socket
    end
  end

  defp on_input(socket, @space_key), do: start_game(socket)

  defp on_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in @left_keys,
       do: move_paddle(socket, :left)

  defp on_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in @right_keys,
       do: move_paddle(socket, :right)

  defp on_input(socket, _), do: socket

  # Handle keyup events
  @spec on_stop_input(Socket.t(), String.t()) :: Socket.t()
  defp on_stop_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in @left_keys,
       do: stop_paddle(socket, :left)

  defp on_stop_input(%{assigns: %{game_state: :playing}} = socket, key)
       when key in @right_keys,
       do: stop_paddle(socket, :right)

  defp on_stop_input(socket, _), do: socket

  defp update_player_name(%{assigns: %{users: users, current_user_id: current_user_id, player_name: player_name}} = socket) do
    Presence.update(self(), @presence, current_user_id, Map.put(users[current_user_id], :name, player_name))
    socket
  end

  defp update_player_level(%{assigns: %{users: users, current_user_id: current_user_id}} = socket, new_level) do
    Presence.update(self(), @presence, current_user_id, Map.put(users[current_user_id], :level, new_level))
    socket
    |> assign(:level, new_level + 1)
  end

  defp update_player_points(%{assigns: %{users: users, current_user_id: current_user_id}} = socket, new_points) do
    Presence.update(self(), @presence, current_user_id, Map.put(users[current_user_id], :points, new_points))
    socket
    |> assign(:score, new_points)
  end

  @spec start_game(Socket.t()) :: Socket.t()
  defp start_game(%{assigns: %{game_state: :welcome}} = socket) do
    assign(socket, :game_state, :name)
  end

  defp start_game(%{assigns: %{game_state: :name}} = socket) do
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

  @spec move_paddle(Socket.t(), :left | :right) :: Socket.t()
  defp move_paddle(%{assigns: %{paddle: paddle}} = socket, direction) do
    if paddle.direction == direction do
      socket
    else
      assign(socket, :paddle, %{paddle | direction: direction})
    end
  end

  @spec stop_paddle(Socket.t(), :left | :right) :: Socket.t()
  defp stop_paddle(%{assigns: %{paddle: paddle}} = socket, direction) do
    if paddle.direction == direction do
      assign(socket, :paddle, %{paddle | direction: :stationary})
    else
      socket
    end
  end

  @spec starting_dx() :: number()
  defp starting_dx,
    do: @starting_angles |> Enum.random() |> :math.cos() |> Kernel.*(@ball_speed)

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: [meta| _]}}, socket ->
      assign(socket, :users, Map.put(socket.assigns.users, user, meta))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      assign(socket, :users, Map.delete(socket.assigns.users, user))
    end)
  end
end
