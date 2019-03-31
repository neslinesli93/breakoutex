defmodule DemoWeb.ArkanoidLive.Engine do
  alias Phoenix.LiveView.Socket

  defmodule DemoWeb.ArkanoidLive.Engine.HitPoint do
    defstruct [:x, :y, :direction]
  end

  alias DemoWeb.ArkanoidLive.Engine.HitPoint

  # Build the four points used to make two segments, which will be checked to
  # compute the interception (if any) and the direction of it
  @spec collision_point(number, number, number, number, number, map) :: HitPoint.t() | nil
  def collision_point(x, y, dx, dy, radius, block) do
    collision_x =
      case {dx, dy} do
        {dx, _} when dx < 0 ->
          compute_collision(
            {x, y},
            {x + dx, y + dy},
            {block.right + radius, block.top - radius},
            {block.right + radius, block.bottom + radius},
            :right
          )

        {dx, _} when dx > 0 ->
          compute_collision(
            {x, y},
            {x + dx, y + dy},
            {block.left - radius, block.top - radius},
            {block.left - radius, block.bottom + radius},
            :left
          )

        _ ->
          nil
      end

    if not is_nil(collision_x) do
      collision_x
    else
      case {dx, dy} do
        {_, dy} when dy < 0 ->
          compute_collision(
            {x, y},
            {x + dx, y + dy},
            {block.left - radius, block.bottom + radius},
            {block.right + radius, block.bottom + radius},
            :bottom
          )

        {_, dy} when dy > 0 ->
          compute_collision(
            {x, y},
            {x + dx, y + dy},
            {block.left - radius, block.top - radius},
            {block.right + radius, block.top - radius},
            :top
          )

        _ ->
          nil
      end
    end
  end

  # Formula that uses the determinant to compute the point of interception between two segments
  defp compute_collision({x1, y1}, {x2, y2}, {x3, y3}, {x4, y4}, direction) do
    denom = (y4 - y3) * (x2 - x1) - (x4 - x3) * (y2 - y1)

    if denom != 0 do
      coeff_a = ((x4 - x3) * (y1 - y3) - (y4 - y3) * (x1 - x3)) / denom
      coeff_b = ((x2 - x1) * (y1 - y3) - (y2 - y1) * (x1 - x3)) / denom

      if coeff_a >= 0 and coeff_a <= 1 and coeff_b >= 0 and coeff_b <= 1 do
        %{
          x: x1 + coeff_a * (x2 - x1),
          y: y1 + coeff_b * (y2 - y1),
          direction: direction
        }
      else
        nil
      end
    else
      nil
    end
  end

  @spec compute_distance({number, number}, {number, number}) :: number
  def compute_distance({x1, y1}, {x2, y2}) do
    :math.sqrt(:math.pow(x1 - x2, 2) + :math.pow(y1 - y2, 2))
  end
end
