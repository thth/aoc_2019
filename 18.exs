defmodule Eighteen do
  def one(input) do
    input
    |> parse()
    |> map_key_distances()
    |> find_paths()
    |> Enum.min_by(fn {list} ->
      Enum.reduce(list, 0, fn {_, d}, acc -> d + acc end)
    end)
    |> elem(0)
    |> Enum.reduce(0, fn {_, d}, acc -> d + acc end)
  end

  def two(input) do
    input
    |> parse()
  end

  defp parse(string) do
    map = %{
      tiles: MapSet.new(),
      entrance: nil,
      keys: %{},
      doors: %{},
      key_locations: MapSet.new(),
      door_locations: MapSet.new()
    }
    parse(string, map, 0, 0)
  end
  defp parse("", map, _x, _y), do: map
  defp parse(<<char::utf8, rest::binary>>,
    %{tiles: tiles, keys: keys, doors: doors,
    key_locations: key_locations, door_locations: door_locations,
    } = map, x, y) do
    case char do
      ?\n -> parse(rest, map, 0, y + 1)
      ?# -> parse(rest, map, x + 1, y)
      ?@ ->
        new_tiles = MapSet.put(tiles, {x, y})
        parse(rest, %{map | tiles: new_tiles, entrance: {x, y}}, x + 1, y)
      ?. ->
        new_tiles = MapSet.put(tiles, {x, y})
        parse(rest, %{map | tiles: new_tiles}, x + 1, y)
      char when char in ?a..?z ->
        new_keys = Map.put(keys, {x, y}, <<char>>)
        new_key_locations = MapSet.put(key_locations, {x, y})
        new_tiles = MapSet.put(tiles, {x, y})
        parse(rest, %{map | keys: new_keys,
          tiles: new_tiles, key_locations: new_key_locations
          }, x + 1, y)
      char when char in ?A..?Z ->
        new_doors = Map.put(doors, {x, y}, String.downcase(<<char>>))
        new_door_locations = MapSet.put(door_locations, {x, y})
        new_tiles = MapSet.put(tiles, {x, y})
        parse(rest, %{map | doors: new_doors,
          tiles: new_tiles, door_locations: new_door_locations
          }, x + 1, y)
    end
  end

  defp map_key_distances(map) do
    map.keys
    |> Map.put(map.entrance, "@")
    |> Enum.map(fn {pos, key} ->
      key_distance_map = calculate_key_distances(map, pos)
      {key, key_distance_map}
    end)
    |> Enum.into(%{})
  end

  defp calculate_key_distances(map, pos) do
    calculate_key_distances(map, pos, [], MapSet.new(), MapSet.new(), 0)
    |> Enum.into(%{})
  end
  defp calculate_key_distances(map, pos, key_list, past_tiles, required_keys, distance) do
    new_key_list =
      if (key = Map.get(map.keys, pos)) && distance != 0 do
        # {key, %{distance: distance, required: required_keys}}
        [{key, %{distance: distance, required: required_keys}} | key_list]
      else
        key_list
      end
    next_tiles =
      pos
      |> surrounding()
      |> Enum.filter(fn coord -> MapSet.member?(map.tiles, coord) end)
      |> MapSet.new()
      |> MapSet.difference(past_tiles)
    if MapSet.size(next_tiles) == 0 do
      new_key_list
    else
      new_past_tiles = MapSet.put(past_tiles, pos)
      new_required_keys =
        cond do
          (key = Map.get(map.keys, pos)) && distance != 0 ->
            MapSet.put(required_keys, key)
          (door = Map.get(map.doors, pos)) && distance != 0 ->
            MapSet.put(required_keys, door)
          true -> required_keys
        end
      Enum.reduce(next_tiles, [], fn tile, acc ->
        [calculate_key_distances(map, tile, new_key_list, new_past_tiles, new_required_keys, distance + 1) | acc]
        |> List.flatten()
      end)
    end
  end

  defp find_paths(distance_map) do
    key_count = map_size(distance_map) - 1
    find_paths(distance_map, [], "@", [], key_count)
    |> List.flatten
  end
  defp find_paths(_distance_map, path, _current_key, obtained_keys, key_count)
    when length(obtained_keys) == key_count do
    {path}
    # path
  end
  defp find_paths(distance_map, path, current_key, obtained_keys, key_count) do
    distance_map
    |> Map.get(current_key)
    |> Map.drop(obtained_keys) # remaining keys
    |> Enum.filter(fn {_key, %{required: required_keys}} -> # accessible keys
      MapSet.subset?(required_keys, MapSet.new(obtained_keys))
    end)
    # |> IO.inspect()
    |> Enum.map(fn {key, %{distance: distance}} ->
      new_path = path ++ [{key, distance}]
      # find_paths(distance_map, new_path, key, [key | obtained_keys], key_count)
      case find_paths(distance_map, new_path, key, [key | obtained_keys], key_count) do
        list when is_list(list) -> List.flatten(list)
        tuple -> tuple
      end
    end)
  end

  # defp map_paths(map) do
  #   key_count = map_size(map.keys)
  #   map_paths(map, map.entrance, [], key_count)
  # end
  # defp map_paths(_map, _current_pos, current_keys, key_count) when length(current_keys) == key_count do
  #   IO.inspect(current_keys)
  #   current_keys
  # end
  # defp map_paths(map, current_pos, current_keys, key_count) do
  #   available_keys = find_available_keys(map, current_pos)
  #   Enum.map(available_keys, fn {key, {distance, pos}} ->
  #     next_map =
  #       %{map | 
  #         tiles: (map.tiles |> MapSet.put(pos) |> MapSet.put(map.doors[key])),
  #         keys: Map.delete(map.keys, pos),
  #         doors: Map.delete(map.doors, key)
  #       }
  #     next_keys = current_keys ++ [{key, distance}]
  #     map_paths(next_map, pos, next_keys, key_count)
  #   end)
  # end

  # defp find_available_keys(map, pos) do
  #   find_available_keys(map, MapSet.new(), MapSet.new([pos]), %{}, 0)
  # end
  # defp find_available_keys(map, prev_tiles, curr_tiles, available_keys, distance) do
  #   if MapSet.size(curr_tiles) == 0 do
  #     available_keys
  #   else
  #     neighbouring_coords =
  #       curr_tiles
  #       |> Enum.map(&surrounding/1)
  #       |> List.flatten()
  #     new_available_keys =
  #       Enum.reduce(neighbouring_coords, available_keys, fn coord, acc ->
  #         if Map.has_key?(map.keys, coord) do
  #           Map.put_new(acc, map.keys[coord], {distance + 1, coord})
  #         else
  #           acc
  #         end
  #       end)
  #     next_tiles =
  #       neighbouring_coords
  #       |> Enum.filter(fn coord -> MapSet.member?(map.tiles, coord) end)
  #       |> MapSet.new()
  #       |> MapSet.difference(prev_tiles)
  #     new_prev_tiles = MapSet.union(prev_tiles, curr_tiles)
  #     find_available_keys(map, new_prev_tiles, next_tiles, new_available_keys, distance + 1)
  #   end
  # end

  defp surrounding({x, y}) do
    [
      {x, y - 1},
      {x, y + 1},
      {x - 1, y},
      {x + 1, y}
    ]
  end
end

# input = File.read!("input/18.txt")
# input =
#   """
#   ########################
#   #@..............ac.GI.b#
#   ###d#e#f################
#   ###A#B#C################
#   ###g#h#i################
#   ########################
#   """
# input =
#   """
#   #########
#   #b.A.@.a#
#   #########
#   """
input =
  """
  #################
  #i.G..c...e..H.p#
  ########.########
  #j.A..b...f..D.o#
  ########@########
  #k.E..a...g..B.n#
  ########.########
  #l.F..d...h..C.m#
  #################
  """
# input =
#   """
#   ########################
#   #f.D.E.e.C.b.A.@.a.B.c.#
#   ######################.#
#   #d.....................#
#   ########################
#   """
# input = "a..b..c..@..d"

:observer.start
Eighteen.one(input)
|> IO.inspect

# Eighteen.two(input)
# |> IO.inspect