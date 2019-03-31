defmodule DemoWeb.ArkanoidLive.Helpers do
  use DemoWeb.ArkanoidLive.Config

  @spec get_color(String.t()) :: String.t()
  def get_color("r"), do: "red"
  def get_color("b"), do: "blue"
  def get_color("g"), do: "green"
  def get_color("y"), do: "yellow"
  def get_color("o"), do: "orange"
  def get_color("p"), do: "purple"

  @spec top_left_x(number, number) :: number
  def top_left_x(x, width), do: x * width

  @spec top_left_y(number, number) :: number
  def top_left_y(y, height), do: y * height

  @spec starting_x() :: number
  def starting_x(), do: @starting_angles |> Enum.random() |> :math.cos() |> Kernel.*(@ball_speed)
end
