defmodule DemoWeb.ArkanoidLive.Board do
  use DemoWeb.ArkanoidLive.Config

  alias DemoWeb.ArkanoidLive.Helpers

  @spec build_board(number) :: [map]
  def build_board(width) do
    {_, blocks} =
      Enum.reduce(@board, {0, []}, fn row, {y_idx, acc} ->
        {_, blocks} =
          Enum.reduce(row, {0, acc}, fn
            "X", {x_idx, acc} ->
              {x_idx + 1, [wall(x_idx, y_idx, width) | acc]}

            "0", {x_idx, acc} ->
              {x_idx + 1, [empty(x_idx, y_idx, width) | acc]}

            "D", {x_idx, acc} ->
              {x_idx + 1, [floor(x_idx, y_idx, width) | acc]}

            b, {x_idx, acc} when b in @brick_colors ->
              {x_idx + 1, [brick(b, x_idx, y_idx, width) | acc]}
          end)

        {y_idx + 1, blocks}
      end)

    blocks
  end

  @spec build_bricks([map]) :: [map]
  def build_bricks(blocks) do
    blocks
    |> Enum.filter(&(&1.type == :brick))
  end

  defp wall(x_idx, y_idx, width) do
    %{
      type: :wall,
      x: Helpers.x_coord(x_idx, width),
      y: Helpers.y_coord(y_idx, width),
      width: width,
      height: width
    }
  end

  defp floor(x_idx, y_idx, width) do
    %{
      type: :floor,
      x: Helpers.x_coord(x_idx, width),
      y: Helpers.y_coord(y_idx, width),
      width: width,
      height: width
    }
  end

  defp empty(x_idx, y_idx, width) do
    %{
      type: :empty,
      x: Helpers.x_coord(x_idx, width),
      y: Helpers.y_coord(y_idx, width),
      width: width,
      height: width
    }
  end

  defp brick(color, x_idx, y_idx, width) do
    %{
      type: :brick,
      color: Helpers.get_color(color),
      x: Helpers.x_coord(x_idx, width),
      y: Helpers.y_coord(y_idx, width),
      width: width * @block_length,
      height: width,
      id: y_idx * @board_rows + x_idx,
      visible: true,
      # collision detection stuff
      top: Helpers.y_coord(y_idx, width),
      bottom: Helpers.y_coord(y_idx, width) + width,
      left: Helpers.x_coord(x_idx, width),
      right: Helpers.x_coord(x_idx, width) + width * @block_length
    }
  end
end
