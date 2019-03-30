defmodule DemoWeb.ArkanoidLive.Config do
  defmacro __using__(_) do
    quote do
      @tick 16
      @width 20

      @brick_colors ~w(r b g o p y)
      @block_length 3

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
      @ball_speed 3
      @ball_width @width / 1.3
      @ball_radius @ball_width / 2

      @left_keys ["ArrowLeft", "a", "A"]
      @right_keys ["ArrowRight", "d", "D"]

      @starting_angles [-60, -45, -30, -15, 15, 30, 45, 60]

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
    end
  end
end
