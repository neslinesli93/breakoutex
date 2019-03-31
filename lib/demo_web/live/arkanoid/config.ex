defmodule DemoWeb.ArkanoidLive.Config do
  defmacro __using__(_) do
    quote do
      # Time in ms that schedules the game loop
      @tick 16
      # Width in px used as the base for every type of block: bricks, paddle, walls, etc.
      # Every length param is expressed as "number of basic unit", that is to say
      # N times the basic unit aka the width
      @width 20

      # Available block colors inside the ascii representation of the board
      @brick_colors ~w(r b g o p y)
      # Brick size
      @brick_length 3

      # x coordinate of the left corner of the paddle
      # TODO: Add top/bottom and left/right
      @paddle_x 10
      @paddle_y 18
      @paddle_length 5
      @paddle_speed 10

      # x coordinate of the left corner of the ball
      # TODO: Use the center of the ball
      @ball_x 12
      @ball_y 17
      @ball_speed 4
      @ball_width @width / 1.5
      @ball_radius @ball_width / 2

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
    end
  end
end
