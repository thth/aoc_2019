defmodule Eighteen do
  def one(input) do
    # %{
    #   tiles: tiles,
    #   keys: keys,
    #   doors: doors,
    #   entrance: entrance
    # } = parse(input)
    input
    |> parse()
    |> map_paths()
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
      # key_locations: MapSet.new(),
      # door_locations: MapSet.new()
    }
    parse(string, map, 0, 0)
  end
  defp parse("", map, _x, _y), do: map
  defp parse(<<char::utf8, rest::binary>>,
    %{tiles: tiles, keys: keys, doors: doors,
    # key_locations: key_locations, door_locations: door_locations,
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
        # new_key_locations = MapSet.put(key_locations, {x, y})
        parse(rest, %{map | keys: new_keys,
          # key_locations: new_key_locations
          }, x + 1, y)
      char when char in ?A..?Z ->
        new_doors = Map.put(doors, String.downcase(<<char>>), {x, y})
        # new_door_locations = MapSet.put(door_locations, {x, y})
        parse(rest, %{map | doors: new_doors,
          # door_locations: new_door_locations
          }, x + 1, y)
    end
  end

  defp map_paths(map) do
    key_count = map_size(map.keys)
    map_paths(map, map.entrance, [], key_count)
  end
  defp map_paths(_map, _current_pos, current_keys, key_count) when length(current_keys) == key_count do
    IO.inspect(current_keys)
    current_keys
  end
  defp map_paths(map, current_pos, current_keys, key_count) do
    available_keys = find_available_keys(map, current_pos)
    Enum.map(available_keys, fn {key, {distance, pos}} ->
      next_map =
        %{map | 
          tiles: (map.tiles |> MapSet.put(pos) |> MapSet.put(map.doors[key])),
          keys: Map.delete(map.keys, pos),
          doors: Map.delete(map.doors, key)
        }
      next_keys = current_keys ++ [{key, distance}]
      map_paths(next_map, pos, next_keys, key_count)
    end)
  end

  defp find_available_keys(map, pos) do
    find_available_keys(map, MapSet.new(), MapSet.new([pos]), %{}, 0)
  end
  defp find_available_keys(map, prev_tiles, curr_tiles, available_keys, distance) do
    if MapSet.size(curr_tiles) == 0 do
      available_keys
    else
      neighbouring_coords =
        curr_tiles
        |> Enum.map(&surrounding/1)
        |> List.flatten()
      new_available_keys =
        Enum.reduce(neighbouring_coords, available_keys, fn coord, acc ->
          if Map.has_key?(map.keys, coord) do
            Map.put_new(acc, map.keys[coord], {distance + 1, coord})
          else
            acc
          end
        end)
      next_tiles =
        neighbouring_coords
        |> Enum.filter(fn coord -> MapSet.member?(map.tiles, coord) end)
        |> MapSet.new()
        |> MapSet.difference(prev_tiles)
      new_prev_tiles = MapSet.union(prev_tiles, curr_tiles)
      find_available_keys(map, new_prev_tiles, next_tiles, new_available_keys, distance + 1)
    end
  end

  defp surrounding({x, y}) do
    [
      {x, y - 1},
      {x, y + 1},
      {x - 1, y},
      {x + 1, y}
    ]
  end
end

input = File.read!("input/18.txt")
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
#   #b.B.@.a#
#   #########
#   """
# input =
#   """
#   #################
#   #i.G..c...e..H.p#
#   ########.########
#   #j.A..b...f..D.o#
#   ########@########
#   #k.E..a...g..B.n#
#   ########.########
#   #l.F..d...h..C.m#
#   #################
#   """

Eighteen.one(input)
|> IO.inspect

# Eighteen.two(input)
# |> IO.inspect