defmodule BreakoutLiveWeb.Live.Config do
  alias BreakoutLiveWeb.Live.Helpers

  defmacro __using__(_) do
    quote do
      # Time in ms that schedules the game loop
      @tick 16
      # Width in pixels, used as the base for every type of block: bricks, paddle, walls, etc.
      # Every length param is expressed as an integer multiple of the basic unit
      @unit 20

      # Available block colors inside the ascii representation of the board
      @brick_colors ~w(r b g o p y)
      # Bricks length expressed in basic units
      @brick_length 3

      # Coordinates of the top-left vertex of the paddle. They are relative to the board matrix
      @paddle_left 10
      @paddle_top 18
      # Paddle length expressed in basic units
      @paddle_length 5
      # Paddle height expressed in basic units
      @paddle_height 1
      # Misc
      @paddle_speed 10

      # Coordinates of the center of the ball, initially a bit above the center of the paddle
      @ball_x 12.5
      @ball_y 17.5
      # Radius of the ball, in pixels
      @ball_radius 5
      # Misc
      @ball_speed 4

      @left_keys ["ArrowLeft", "a", "A"]
      @right_keys ["ArrowRight", "d", "D"]

      @starting_angles [-60, -45, -30, -15, 15, 30, 45, 60]

      # Game board represented as an ASCII matrix. Block types:
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

      defp initial_state() do
        %{
          game_state: :wait,
          tick: @tick,
          # Basic unit for measuring blocks size
          unit: @unit,
          board_rows: @board_rows,
          board_cols: @board_cols,
          left: &left/4,
          paddle: %{
            width: @paddle_length * @unit,
            height: @paddle_height * @unit,
            # Coordinates of the box surrounding the paddle
            left: Helpers.coordinate(@paddle_left, @unit),
            top: Helpers.coordinate(@paddle_top, @unit),
            right: Helpers.coordinate(@paddle_left + @paddle_length, @unit),
            bottom: Helpers.coordinate(@paddle_top + @paddle_height, @unit),
            # Add some fields for compatibility with bricks
            id: "paddle",
            type: :paddle,
            visible: true,
            # Misc
            direction: :stationary,
            speed: @paddle_speed,
            length: @paddle_length
          },
          ball: %{
            radius: @ball_radius,
            # Coordinates of the center
            x: Helpers.coordinate(@ball_x, @unit),
            y: Helpers.coordinate(@ball_y, @unit),
            # Movement of the ball in the two axis
            dx: 0,
            dy: 0,
            # Box surrounding the ball. We don't need all the coordinates, since we just use
            # the top-left vertex for drawing
            left: Helpers.coordinate(@ball_x, @unit) - @ball_radius,
            top: Helpers.coordinate(@ball_y, @unit) - @ball_radius,
            width: 2 * @ball_radius,
            height: 2 * @ball_radius,
            # Misc
            speed: @ball_speed
          }
        }
      end

      # Horizontally center the board
      defp left(x, unit, rows, _) do
        "calc(50% + #{unit * rows / 2}px + #{x}px)"
      end
    end
  end
end
