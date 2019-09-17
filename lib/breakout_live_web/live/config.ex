defmodule BreakoutLiveWeb.Live.Config do
  @moduledoc """
  Module that holds all the constants and initial state of the game
  """

  alias BreakoutLiveWeb.Live.Helpers

  defmacro __using__(_) do
    # credo:disable-for-next-line Credo.Check.Refactor.LongQuoteBlocks
    quote do
      # Time in ms that schedules the game loop
      @tick 16
      # Width in pixels, used as the base for every type of block: bricks, paddle, walls, etc.
      # Every length param is expressed as an integer multiple of the basic unit
      @unit 20

      # Available block colors inside the ascii representation of the board
      @brick_colors ~w(r b g o p y t w)

      # Coordinates of the top-left vertex of the paddle. They are relative to the board matrix
      @paddle_left 11
      @paddle_top 18
      # Paddle length expressed in basic units
      @paddle_length 5
      # Paddle height expressed in basic units
      @paddle_height 1
      # Misc
      @paddle_speed 5

      # Coordinates of the center of the ball, initially a bit above the center of the paddle
      @ball_x 13.5
      @ball_y 17.5
      # Radius of the ball, in pixels
      @ball_radius 5
      # Misc
      @ball_speed 4

      @left_keys ["ArrowLeft", "a", "A"]
      @right_keys ["ArrowRight", "d", "D"]

      @starting_angles Enum.concat([-60..-15, 15..60])

      @board_rows 21
      @board_cols 26

      # Game board is represented as an ASCII matrix. Block types:
      # - X are the walls
      # - D is the floor
      # - r, b, g, o, p, y, t, w are the colors of the different blocks
      #
      # Brick length is expressed in basic units
      @levels [
        %{
          brick_length: 3,
          grid: [
            ~w(X X X X X X X X X X X X X X X X X X X X X X X X X X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X r 0 0 r 0 0 r 0 0 r 0 0 r 0 0 r 0 0 r 0 0 r 0 0 X),
            ~w(X b 0 0 b 0 0 b 0 0 b 0 0 b 0 0 b 0 0 b 0 0 b 0 0 X),
            ~w(X g 0 0 g 0 0 g 0 0 g 0 0 g 0 0 g 0 0 g 0 0 g 0 0 X),
            ~w(X o 0 0 o 0 0 o 0 0 o 0 0 o 0 0 o 0 0 o 0 0 o 0 0 X),
            ~w(X p 0 0 p 0 0 p 0 0 p 0 0 p 0 0 p 0 0 p 0 0 p 0 0 X),
            ~w(X y 0 0 y 0 0 y 0 0 y 0 0 y 0 0 y 0 0 y 0 0 y 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(D D D D D D D D D D D D D D D D D D D D D D D D D D)
          ]
        },
        %{
          brick_length: 3,
          grid: [
            ~w(X X X X X X X X X X X X X X X X X X X X X X X X X X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X r 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X b 0 0 b 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X g 0 0 g 0 0 g 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X o 0 0 o 0 0 o 0 0 o 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X p 0 0 p 0 0 p 0 0 p 0 0 p 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X y 0 0 y 0 0 y 0 0 y 0 0 y 0 0 y 0 0 0 0 0 0 0 0 X),
            ~w(X t 0 0 t 0 0 t 0 0 t 0 0 t 0 0 t 0 0 t 0 0 0 0 0 X),
            ~w(X w 0 0 w 0 0 w 0 0 w 0 0 w 0 0 w 0 0 w 0 0 w 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(D D D D D D D D D D D D D D D D D D D D D D D D D D)
          ]
        },
        %{
          brick_length: 2,
          grid: [
            ~w(X X X X X X X X X X X X X X X X X X X X X X X X X X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 p 0 p 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 p 0 b 0 b 0 p 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 p 0 b 0 b 0 b 0 b 0 p 0 0 0 0 0 X),
            ~w(X p 0 0 0 0 0 p 0 b 0 b 0 t 0 t 0 b 0 b 0 p 0 0 0 X),
            ~w(X b 0 p 0 p 0 b 0 b 0 t 0 w 0 w 0 t 0 b 0 b 0 p 0 X),
            ~w(X b 0 b 0 b 0 b 0 t 0 w 0 0 0 0 0 w 0 t 0 b 0 b 0 X),
            ~w(X t 0 b 0 b 0 t 0 w 0 0 0 0 0 0 0 0 0 w 0 t 0 b 0 X),
            ~w(X w 0 t 0 t 0 w 0 0 0 0 0 0 0 0 0 0 0 0 0 w 0 t 0 X),
            ~w(X 0 0 w 0 w 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 w 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(X 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 X),
            ~w(D D D D D D D D D D D D D D D D D D D D D D D D D D)
          ]
        }
      ]

      @levels_no length(@levels)

      defp initial_state() do
        %{
          game_state: :welcome,
          tick: @tick,
          level: 0,
          lost_lives: 0,
          # Basic unit for measuring blocks size
          unit: @unit,
          board_rows: @board_rows,
          board_cols: @board_cols,
          paddle: initial_paddle_state(),
          ball: initial_ball_state()
        }
      end

      defp initial_paddle_state() do
        %{
          width: @paddle_length * @unit,
          height: @paddle_height * @unit,
          # Coordinates of the box surrounding the paddle
          left: Helpers.coordinate(@paddle_left, @unit),
          top: Helpers.coordinate(@paddle_top, @unit),
          right: Helpers.coordinate(@paddle_left + @paddle_length, @unit),
          bottom: Helpers.coordinate(@paddle_top + @paddle_height, @unit),
          # Add some fields for compatibility with bricks
          id: UUID.uuid4(),
          type: :paddle,
          visible: true,
          # Misc
          direction: :stationary,
          speed: @paddle_speed,
          length: @paddle_length
        }
      end

      defp initial_ball_state() do
        %{
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
      end
    end
  end
end
