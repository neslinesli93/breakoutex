defmodule DemoWeb.ArkanoidLive.Helpers do
  use DemoWeb.ArkanoidLive.Config

  @spec get_color(String.t()) :: String.t()
  def get_color("r"), do: "red"
  def get_color("b"), do: "blue"
  def get_color("g"), do: "green"
  def get_color("y"), do: "yellow"
  def get_color("o"), do: "orange"
  def get_color("p"), do: "purple"

  # Multiply an integer coordinate for a length, giving
  # the actual coordinate on a continuous plane
  @spec coordinate(number, number) :: number
  def coordinate(x, l), do: x * l

  @spec starting_dx() :: number
  def starting_dx(), do: @starting_angles |> Enum.random() |> :math.cos() |> Kernel.*(@ball_speed)
end
