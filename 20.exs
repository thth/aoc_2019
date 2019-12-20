defmodule Twenty do
  def one(input) do
    input
    |> parse()
    |> find_shortest_path()
  end

  def two(input) do
    input
    |> parse()
    |> two_find_shortest_path()
  end

  defp two_find_shortest_path(%{entrance: entrance} = map) do
    two_find_shortest_path(map, MapSet.new(), MapSet.new([{0, entrance}]), 0)
  end

  defp two_find_shortest_path(%{
      tiles: tiles,
      portals: portals,
      exit_pos: exit_pos,
      maze_range: maze_range,
    } = map, prev_tiles, curr_tiles, distance) do
    if MapSet.member?(curr_tiles, {0, exit_pos}) do
      distance
    else
      destinations_mapset = Enum.reduce(curr_tiles, MapSet.new(), fn tile, acc ->
        case two_portal_destination(portals, tile, maze_range) do
          nil -> acc
          destination -> MapSet.put(acc, destination)
        end
      end)
      next_tiles =
        curr_tiles
        |> Enum.map(fn {level, pos} ->
          surrounding(pos)
          |> Enum.map(&({level, &1}))
        end)
        |> List.flatten()
        |> Enum.filter(fn {_level, tile} -> MapSet.member?(tiles, tile) end)
        |> MapSet.new()
        |> MapSet.union(destinations_mapset)
        |> MapSet.difference(prev_tiles)
      new_prev_tiles = MapSet.union(prev_tiles, curr_tiles)
      two_find_shortest_path(map, new_prev_tiles, next_tiles, distance + 1)
    end
  end

  defp two_portal_destination(portals, {level, pos}, maze_range) do
    portals
    |> Enum.find_value(fn {_portal, tiles} ->
      if (level > 0 or !outer_portal?(pos, maze_range)) and (pos in tiles) do
        case Enum.find_index(tiles, &(&1 == pos)) do
          0 -> {level + 1, Enum.at(tiles, 1)}
          1 -> {level - 1, Enum.at(tiles, 0)}
        end
      else
        nil
      end
    end)
  end

  defp find_shortest_path(%{entrance: entrance} = map) do
    find_shortest_path(map, MapSet.new(), MapSet.new([entrance]), 0)
  end

  defp find_shortest_path(%{
      tiles: tiles,
      portals: portals,
      exit_pos: exit_pos,
    } = map, prev_tiles, curr_tiles, distance) do
    if MapSet.member?(curr_tiles, exit_pos) do
      distance
    else
      destinations_mapset = Enum.reduce(curr_tiles, MapSet.new(), fn tile, acc ->
        case portal_destinations(portals, tile) do
          nil -> acc
          destinations ->
            destinations
            |> MapSet.new()
            |> MapSet.union(acc)
        end
      end)
      next_tiles =
        curr_tiles
        |> Enum.map(&surrounding/1)
        |> List.flatten()
        |> Enum.filter(fn tile -> MapSet.member?(tiles, tile) end)
        |> MapSet.new()
        |> MapSet.union(destinations_mapset)
        |> MapSet.difference(prev_tiles)
      new_prev_tiles = MapSet.union(prev_tiles, curr_tiles)
      find_shortest_path(map, new_prev_tiles, next_tiles, distance + 1)
    end
  end

  defp portal_destinations(portals, pos) do
    portals
    |> Enum.find_value([], fn {_portal, tiles} ->
      if pos in tiles do
        tiles -- [pos]
      else
        nil
      end
    end)
  end

  defp parse(string) do
    charlists =
      string
      |> String.split("\n")
      |> Enum.map(&String.to_charlist/1)
    {y_min, y_max} =
      charlists
      |> Enum.with_index()
      |> Enum.filter(fn {line, _y} -> ?# in line end)
      |> (fn lines ->
        {elem(List.first(lines), 1), elem(List.last(lines), 1)}
      end).()
    {x_min, x_max} =
      charlists
      |> Enum.at(y_min)
      |> Enum.with_index()
      |> Enum.filter(fn {char, _x} -> char != ?\s end)
      |> (fn line ->
        {elem(List.first(line), 1), elem(List.last(line), 1)}
      end).()
    map = %{
      tiles: MapSet.new(),
      portals: %{},
      entrance: nil,
      exit_pos: nil,
      maze_range: {{x_min, x_max}, {y_min, y_max}},
    }
    parse(charlists, charlists, map, 0, 0)
  end

  defp parse(_original, [], map, _x, _y), do: map
  defp parse(original, [[] | rest_lists], map, _x, y), do: parse(original, rest_lists, map, 0, y + 1)
  defp parse(original, [[char | rest_charlist] | rest_lists], %{
      tiles: tiles,
      portals: portals,
      maze_range: maze_range,
    } = map, x, y) do
    case char do
      ?. ->
        new_tiles = MapSet.put(tiles, {x, y})
        case parse_portal(original, {x, y}) do
          nil ->
            parse(original, [rest_charlist | rest_lists],
              %{map | tiles: new_tiles}, x + 1, y)
          "AA" ->
            parse(original, [rest_charlist | rest_lists],
              %{map | tiles: new_tiles, entrance: {x, y}}, x + 1, y)
          "ZZ" ->
            parse(original, [rest_charlist | rest_lists],
              %{map | tiles: new_tiles, exit_pos: {x, y}}, x + 1, y)
          portal ->
            new_portals = Map.update(portals, portal, [{x, y}], fn pos_list ->
              if outer_portal?({x, y}, maze_range) do
                pos_list ++ [{x, y}]
              else
                [{x, y} | pos_list]
              end
            end)
            parse(original, [rest_charlist | rest_lists], %{map |
                tiles: new_tiles,
                portals: new_portals,
              }, x + 1, y)
        end
      _ ->
        parse(original, [rest_charlist | rest_lists], map, x + 1, y)
    end
  end

  defp parse_portal(charlists, {x, y}) do
    {x, y}
    |> surrounding()
    |> Enum.find_value(fn {i, j} ->
      with true <- x >= 0,
           true <- y >= 0,
           line <- Enum.at(charlists, j),
           char <- Enum.at(line, i),
           true <- char in ?A..?Z do
        {char2, {x2, y2}} =
          surrounding({i, j})
          |> Enum.find_value(fn {a, b} ->
            letter =
              charlists
              |> Enum.at(b)
              |> Enum.at(a)
            if letter in ?A..?Z, do: {letter, {a, b}}, else: nil
          end)
        if x < x2 or y < y2 do
          List.to_string([char, char2])
        else
          List.to_string([char2, char])
        end
      else
        _ -> nil
      end
    end)
  end

  defp outer_portal?({x, y}, {{x_min, x_max}, {y_min, y_max}}) do
    x == x_min or x == x_max or y == y_min or y == y_max
  end

  defp surrounding({x, y}) do
    [{x, y - 1}, {x, y + 1}, {x - 1, y}, {x + 1, y}]
  end
end

input = File.read!("input/20.txt")

Twenty.one(input)
|> IO.inspect

Twenty.two(input)
|> IO.inspect
