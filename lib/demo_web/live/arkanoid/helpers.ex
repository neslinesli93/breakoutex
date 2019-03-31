defmodule DemoWeb.ArkanoidLive.Helpers do
  use DemoWeb.ArkanoidLive.Config

  # Multiply an integer coordinate for a length, giving
  # the actual coordinate on a continuous plane
  @spec coordinate(number, number) :: number
  def coordinate(x, l), do: x * l
end
