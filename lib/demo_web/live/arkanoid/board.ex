defmodule DemoWeb.ArkanoidLive.Board do
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

  @spec build_bricks(number, number) :: [map]
  def build_bricks(width, height) do
    width
    |> build_board(height)
    |> Enum.filter(&(&1.type == :brick))
  end

  defp wall(x_idx, y_idx, width, height) do
    %{
      type: :wall,
      x: Helpers.top_left_x(x_idx, width),
      y: Helpers.top_left_y(y_idx, height),
      width: width,
      height: height
    }
  end

  defp floor(x_idx, y_idx, width, height) do
    %{
      type: :floor,
      x: Helpers.top_left_x(x_idx, width),
      y: Helpers.top_left_y(y_idx, height),
      width: width,
      height: height
    }
  end

  defp empty(x_idx, y_idx, width, height) do
    %{
      type: :empty,
      x: Helpers.top_left_x(x_idx, width),
      y: Helpers.top_left_y(y_idx, height),
      width: width,
      height: height
    }
  end

  defp brick(color, x_idx, y_idx, width, height) do
    %{
      type: :brick,
      color: Helpers.get_color(color),
      x: Helpers.top_left_x(x_idx, width),
      y: Helpers.top_left_y(y_idx, height),
      width: width * @brick_length,
      height: height,
      id: y_idx * @board_rows + x_idx,
      visible: true,
      # collision detection stuff
      top: Helpers.top_left_y(y_idx, height),
      bottom: Helpers.top_left_y(y_idx, height) + height,
      left: Helpers.top_left_x(x_idx, width),
      right: Helpers.top_left_x(x_idx, width) + width * @brick_length
    }
  end
end
