defmodule BreakoutexWeb.Live.Config do
  # credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks

  @moduledoc """
  Module that holds all the constants and initial state of the game
  """

  alias BreakoutexWeb.Live.Helpers

  defmacro __using__(_) do
    quote do
      # CONSTANTS

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

      @space_key " "
      @left_keys ["ArrowLeft", "a"]
      @right_keys ["ArrowRight", "d"]
      @backspace ["Backspace"]
      @return ["Enter"]
      @starting_angles Enum.concat([-60..-15, 15..60])

      @board_rows 21
      @board_cols 26

      @points_subtracted_on_lost_life 100
      @starting_multiplier 1
      @points_for_brick 20

      # Game board is represented as an ASCII matrix. Block types:
      # - X are the walls
      # - D is the floor
      # - r, b, g, o, p, y, t, w are the colors of the different blocks
      #
      # Brick length is expressed in basic units
      @levels System.get_env("LEVELS") ||
                [
                  %{
                    brick_length: 3,
                    message: "year in review message 1",
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
                    message: "year in review message 2",
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
                    message: "year in review message 3",
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

      # TYPES

      @type block :: %{
              type: :wall | :floor | :empty,
              left: number(),
              top: number(),
              width: number(),
              height: number()
            }

      @type brick :: %{
              type: :brick,
              color: String.t(),
              width: number(),
              height: number(),
              id: String.t(),
              visible: boolean(),
              left: number(),
              top: number(),
              right: number(),
              bottom: number()
            }

      @type paddle :: %{
              width: number(),
              height: number(),
              left: number(),
              top: number(),
              right: number(),
              bottom: number(),
              id: String.t(),
              type: :paddle,
              visible: boolean(),
              direction: :left | :right | :stationary,
              speed: number(),
              length: number()
            }

      @type ball :: %{
              radius: number(),
              x: number(),
              y: number(),
              dx: number(),
              dy: number(),
              width: number(),
              height: number(),
              speed: number()
            }

      @spec initial_state() :: map()
      defp initial_state do
        %{
          game_state: :welcome,
          tick: @tick,
          level: 0,
          lost_lives: 0,
          score: 0,
          user_id: "user#" <> Integer.to_string(System.os_time(:second)),
          player_name: "",
          multiplier: @starting_multiplier,
          secret_message: Enum.at(@levels, 0) |> Map.get(:message),
          # Basic unit for measuring blocks size
          unit: @unit,
          board_rows: @board_rows,
          board_cols: @board_cols,
          paddle: initial_paddle_state(),
          ball: initial_ball_state()
        }
      end

      @spec initial_paddle_state() :: paddle()
      defp initial_paddle_state do
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

      @spec initial_ball_state() :: ball()
      defp initial_ball_state do
        %{
          radius: @ball_radius,
          # Coordinates of the center
          x: Helpers.coordinate(@ball_x, @unit),
          y: Helpers.coordinate(@ball_y, @unit),
          # Movement of the ball in the two axis
          dx: 0,
          dy: 0,
          # Misc
          width: 2 * @ball_radius,
          height: 2 * @ball_radius,
          speed: @ball_speed
        }
      end
    end
  end
end
