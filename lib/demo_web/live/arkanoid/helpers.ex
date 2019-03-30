defmodule DemoWeb.ArkanoidLive.Helpers do
  @spec get_color(String.t()) :: String.t()
  def get_color("r"), do: "red"
  def get_color("b"), do: "blue"
  def get_color("g"), do: "green"
  def get_color("y"), do: "yellow"
  def get_color("o"), do: "orange"
  def get_color("p"), do: "purple"

  @spec x_coord(number, number) :: number
  def x_coord(x, width), do: x * width

  @spec y_coord(number, number) :: number
  def y_coord(y, width), do: y * width
end
