defmodule BreakoutLiveWeb.Live.Blocks do
  @moduledoc """
  Module that contains the definitions of all the block types:
  bricks, paddle, etc
  """

  use BreakoutLiveWeb.Live.Config

  alias BreakoutLiveWeb.Live.Helpers

  @spec build_board(number, number, number) :: [map]
  def build_board(level, width, height) do
    %{grid: grid, brick_length: brick_length} = Enum.at(@levels, level)

    {_, blocks} =
      Enum.reduce(grid, {0, []}, fn row, {y_idx, acc} ->
        {_, blocks} =
          Enum.reduce(row, {0, acc}, fn
            "X", {x_idx, acc} ->
              {x_idx + 1, [wall(x_idx, y_idx, width, height) | acc]}

            "0", {x_idx, acc} ->
              {x_idx + 1, [empty(x_idx, y_idx, width, height) | acc]}

            "D", {x_idx, acc} ->
              {x_idx + 1, [floor(x_idx, y_idx, width, height) | acc]}

            b, {x_idx, acc} when b in @brick_colors ->
              {x_idx + 1, [brick(b, brick_length, x_idx, y_idx, width, height) | acc]}
          end)

        {y_idx + 1, blocks}
      end)

    blocks
  end

  @spec build_bricks(number, number, number) :: [map]
  def build_bricks(level, width, height) do
    level
    |> build_board(width, height)
    |> Enum.filter(&(&1.type == :brick))
  end

  defp wall(x_idx, y_idx, width, height) do
    %{
      type: :wall,
      left: Helpers.coordinate(x_idx, width),
      top: Helpers.coordinate(y_idx, height),
      width: width,
      height: height
    }
  end

  defp floor(x_idx, y_idx, width, height) do
    %{
      type: :floor,
      left: Helpers.coordinate(x_idx, width),
      top: Helpers.coordinate(y_idx, height),
      width: width,
      height: height
    }
  end

  defp empty(x_idx, y_idx, width, height) do
    %{
      type: :empty,
      left: Helpers.coordinate(x_idx, width),
      top: Helpers.coordinate(y_idx, height),
      width: width,
      height: height
    }
  end

  defp brick(color, brick_length, x_idx, y_idx, width, height) do
    %{
      type: :brick,
      color: get_color(color),
      width: width * brick_length,
      height: height,
      id: UUID.uuid4(),
      visible: true,
      left: Helpers.coordinate(x_idx, width),
      top: Helpers.coordinate(y_idx, height),
      right: Helpers.coordinate(x_idx, width) + width * brick_length,
      bottom: Helpers.coordinate(y_idx, height) + height
    }
  end

  defp get_color("r"), do: "red"
  defp get_color("b"), do: "blue"
  defp get_color("g"), do: "green"
  defp get_color("y"), do: "yellow"
  defp get_color("o"), do: "orange"
  defp get_color("p"), do: "purple"
  defp get_color("t"), do: "turquoise"
  defp get_color("w"), do: "white"
end
