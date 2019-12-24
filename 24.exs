defmodule TwentyFour do
  @two_minutes 200

  def one(input) do
    input
    |> parse()
    |> step_until_repeat()
  end

  def two(input) do
    input
    |> parse_two()
    |> step_until_steps(@two_minutes)
    |> MapSet.size()
  end

  def parse(raw) do
    map = for x <- 0..4, y <- 0..4, into: %{}, do: {{x, y}, false}

    raw
    |> String.trim()
    |> parse(map, 0, 0)
  end

  def parse("", map, _x, _y), do: map
  def parse("\n" <> rest, map, _x, y), do: parse(rest, map, 0, y + 1)
  def parse("." <> rest, map, x, y), do: parse(rest, map, x + 1, y)
  def parse("#" <> rest, map, x, y) do
    new_map = Map.put(map, {x, y}, true)
    parse(rest, new_map, x + 1, y)
  end

  def parse_two(raw) do
    raw
    |> String.trim()
    |> parse_two(MapSet.new(), 0, 0)
  end

  def parse_two("", mapset, _x, _y), do: mapset
  def parse_two("\n" <> rest, mapset, _x, y), do: parse_two(rest, mapset, 0, y + 1)
  def parse_two("." <> rest, mapset, x, y), do: parse_two(rest, mapset, x + 1, y)
  def parse_two("#" <> rest, mapset, x, y) do
    new_mapset = MapSet.put(mapset, {0, {x, y}})
    parse_two(rest, new_mapset, x + 1, y)
  end

  defp step_until_repeat(map), do: step_until_repeat(map, MapSet.new())
  defp step_until_repeat(map, past_states) do
    new_map = step_map(map)
    diversity = calculate_diversity(new_map)
    if MapSet.member?(past_states, diversity) do
      diversity
    else
      step_until_repeat(new_map, MapSet.put(past_states, diversity))
    end
  end

  defp step_map(map) do
    Enum.map(map, fn {{x, y}, bug?} ->
      neighbours =
        surrounding({x, y})
        |> Enum.map(fn pos -> Map.get(map, pos, false) end)
        |> Enum.count(&(&1))
      new_bug? =
        cond do
          bug? and neighbours == 1 -> true
          bug? -> false
          neighbours == 1 or neighbours == 2 -> true
          true -> false
        end
      {{x, y}, new_bug?}
    end)
    |> Enum.into(%{})
  end

  defp calculate_diversity(map) do
    map
    |> Enum.reduce(0, fn {{x, y}, bug?}, acc ->
      if bug?, do: acc + trunc(:math.pow(2, y * 5 + x)), else: acc
    end)
  end

  defp step_until_steps(mapset, steps, i \\ 0)
  defp step_until_steps(mapset, steps, i) when i == steps, do: mapset
  defp step_until_steps(mapset, steps, i) do
    new_mapset =
      mapset
      |> Enum.reduce(MapSet.new(), fn pos, acc ->
        neighbours = pluto_surrounding(pos)
        neighbour_points = neighbours_biogenesis(mapset, neighbours)
        neighbour_count = Enum.count(neighbours, &(MapSet.member?(mapset, &1)))
        if neighbour_count == 1 do
          acc
          |> MapSet.put(pos)
          |> MapSet.union(neighbour_points)
        else
          MapSet.union(acc, neighbour_points)
        end
      end)
    step_until_steps(new_mapset, steps, i + 1)
  end

  defp neighbours_biogenesis(mapset, neighbours) do
    Enum.reduce(neighbours, MapSet.new(), fn pos, acc ->
      with false <- MapSet.member?(mapset, pos),
           neighbour_count <-
            Enum.count(pluto_surrounding(pos), fn point ->
              MapSet.member?(mapset, point)
            end),
           true <- neighbour_count == 1 or neighbour_count == 2 do
        MapSet.put(acc, pos)
      else
        _ -> acc
      end
    end)
  end

  def draw(mapset) do
    {min_level, _} = Enum.min_by(mapset, fn {level, _} -> level end)
    {max_level, _} = Enum.max_by(mapset, fn {level, _} -> level end)
    min_level..max_level
    |> Enum.each(fn level ->
      IO.puts("level: #{level}")
      0..4
      |> Enum.each(fn y ->
        0..4
        |> Enum.reduce("", fn x, acc ->
          if MapSet.member?(mapset, {level, {x, y}}), do: acc <> "#", else: acc <> "."
        end)
        |> IO.puts()
      end)
      IO.puts("")
    end)
    mapset
  end

  defp pluto_surrounding({level, {x, y}}) when x == 2 and y == 1, do:
    [{level, {x, y - 1}}, {level, {x - 1, y}}, {level, {x + 1, y}}]
      ++ for i <- 0..4, do: {level + 1, {i, 0}}
  defp pluto_surrounding({level, {x, y}}) when x == 2 and y == 3, do:
    [{level, {x, y + 1}}, {level, {x - 1, y}}, {level, {x + 1, y}}]
      ++ for i <- 0..4, do: {level + 1, {i, 4}}
  defp pluto_surrounding({level, {x, y}}) when x == 1 and y == 2, do:
    [{level, {x, y - 1}}, {level, {x, y + 1}}, {level, {x - 1, y}}]
      ++ for j <- 0..4, do: {level + 1, {0, j}}
  defp pluto_surrounding({level, {x, y}}) when x == 3 and y == 2, do:
    [{level, {x, y - 1}}, {level, {x, y + 1}}, {level, {x + 1, y}}]
      ++ for j <- 0..4, do: {level + 1, {4, j}}
  defp pluto_surrounding({level, {x, y}}) do
    north = if y == 0, do: {level - 1, {2, 1}}, else: {level, {x, y - 1}}
    south = if y == 4, do: {level - 1, {2, 3}}, else: {level, {x, y + 1}}
    west = if x == 0, do: {level - 1, {1, 2}}, else: {level, {x - 1, y}}
    east = if x == 4, do: {level - 1, {3, 2}}, else: {level, {x + 1, y}}
    [north, south, west, east]
  end

  defp surrounding({x, y}) do
    [{x, y - 1}, {x, y + 1}, {x - 1, y}, {x + 1, y}]
  end
end

input = File.read!("input/24.txt")
TwentyFour.one(input)
|> IO.inspect

TwentyFour.two(input)
|> IO.inspect
