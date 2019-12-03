defmodule Three do
  def one(input) do
    input
    |> parse_one()
    |> (fn {a, b} -> MapSet.intersection(a, b) end).()
    |> Stream.map(&manhattan_distance/1)
    |> Enum.min()
  end

  def two(input) do
    input
    |> parse_two()
    |> stepmap_shortest()
  end

  def parse_one(raw) do
    raw
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> String.split(",")
      |> convert_to_mapset(MapSet.new())
    end)
    |> List.to_tuple()
  end

  defp convert_to_mapset(list, mapset, pos \\ {0, 0})
  defp convert_to_mapset([], mapset, _), do: mapset
  defp convert_to_mapset([ins | rest], mapset, {x, y}) do
    {dir, steps} = String.split_at(ins, 1)
    steps = String.to_integer(steps)
    {coords_to_add, new_pos} =
      case dir do
        "U" ->
          {(for j <- 1..steps, do: {x, y + j}) |> MapSet.new(), {x, y + steps}}
        "D" ->
          {(for j <- 1..steps, do: {x, y - j}) |> MapSet.new(), {x, y - steps}}
        "L" ->
          {(for i <- 1..steps, do: {x - i, y}) |> MapSet.new(), {x - steps, y}}
        "R" ->
          {(for i <- 1..steps, do: {x + i, y}) |> MapSet.new(), {x + steps, y}}
      end
    convert_to_mapset(rest, MapSet.union(mapset, coords_to_add), new_pos)
  end

  defp manhattan_distance({x, y}) do
    abs(x) + abs(y)
  end

  def parse_two(raw) do
    raw
    |> String.split("\n")
    |> Enum.map(fn line ->
      line
      |> String.split(",")
      |> convert_to_stepmap()
    end)
    |> List.to_tuple()
  end

  defp convert_to_stepmap(list, stepmap \\ %{}, steps_taken \\ 0, pos \\ {0, 0})
  defp convert_to_stepmap([], stepmap, _, _), do: stepmap
  defp convert_to_stepmap([ins | rest], stepmap, steps_taken, {x, y}) do
    {dir, steps_to_take} = String.split_at(ins, 1)
    steps_to_take = String.to_integer(steps_to_take)
    new_steps_taken = steps_taken + steps_to_take
    {steps_to_add, new_pos} =
      case dir do
        "U" ->
          {(for j <- 1..steps_to_take, do: {{x, y + j}, steps_taken + j}, into: %{}), {x, y + steps_to_take}}
        "D" ->
          {(for j <- 1..steps_to_take, do: {{x, y - j}, steps_taken + j}, into: %{}), {x, y - steps_to_take}}
        "L" ->
          {(for i <- 1..steps_to_take, do: {{x - i, y}, steps_taken + i}, into: %{}), {x - steps_to_take, y}}
        "R" ->
          {(for i <- 1..steps_to_take, do: {{x + i, y}, steps_taken + i}, into: %{}), {x + steps_to_take, y}}
      end
    new_map = Map.merge(steps_to_add, stepmap)
    convert_to_stepmap(rest, new_map, new_steps_taken, new_pos)
  end

  defp stepmap_shortest({a, b}) do
    a_pos = Map.keys(a) |> MapSet.new()
    b_pos = Map.keys(b) |> MapSet.new()
    intersections = MapSet.intersection(a_pos, b_pos)
    for pos <- intersections do
      Map.fetch!(a, pos) + Map.fetch!(b, pos)
    end
    |> Enum.min()
  end
end

input = File.read!("input/03.txt")

Three.one(input)
|> IO.inspect

Three.two(input)
|> IO.inspect
