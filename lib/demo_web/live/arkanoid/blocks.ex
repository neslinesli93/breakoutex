defmodule DemoWeb.ArkanoidLive.Blocks do
  use DemoWeb.ArkanoidLive.Config

  alias DemoWeb.ArkanoidLive.Helpers

  @spec build_board(number, number) :: [map]
  def build_board(width, height) do
    {_, blocks} =
      Enum.reduce(@board, {0, []}, fn row, {y_idx, acc} ->
        {_, blocks} =
          Enum.reduce(row, {0, acc}, fn
            "X", {x_idx, acc} ->
              {x_idx + 1, [wall(x_idx, y_idx, width, height) | acc]}

            "0", {x_idx, acc} ->
              {x_idx + 1, [empty(x_idx, y_idx, width, height) | acc]}

            "D", {x_idx, acc} ->
              {x_idx + 1, [floor(x_idx, y_idx, width, height) | acc]}

            b, {x_idx, acc} when b in @brick_colors ->
              {x_idx + 1, [brick(b, x_idx, y_idx, width, height) | acc]}
          end)

        {y_idx + 1, blocks}
      end)

    blocks
  end

  @spec build_obstacles(number, number) :: [map]
  def build_obstacles(width, height) do
    width
    |> build_board(height)
    |> Enum.filter(&(&1.type in [:brick, :wall]))
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

  defp wall(x_idx, y_idx, width, height) do
    %{
      type: :wall,
      width: width,
      height: height,
      id: y_idx * @board_rows + x_idx,
      visible: true,
      left: Helpers.coordinate(x_idx, width),
      top: Helpers.coordinate(y_idx, height),
      right: Helpers.coordinate(x_idx, width) + width,
      bottom: Helpers.coordinate(y_idx, height) + height
    }
  end

  defp brick(color, x_idx, y_idx, width, height) do
    %{
      type: :brick,
      color: get_color(color),
      width: width * @brick_length,
      height: height,
      id: y_idx * @board_rows + x_idx,
      visible: true,
      left: Helpers.coordinate(x_idx, width),
      top: Helpers.coordinate(y_idx, height),
      right: Helpers.coordinate(x_idx, width) + width * @brick_length,
      bottom: Helpers.coordinate(y_idx, height) + height
    }
  end

  defp get_color("r"), do: "red"
  defp get_color("b"), do: "blue"
  defp get_color("g"), do: "green"
  defp get_color("y"), do: "yellow"
  defp get_color("o"), do: "orange"
  defp get_color("p"), do: "purple"
end
