defmodule Eighteen do
  def one(input) do
    input
    |> parse()
    |> map_key_distances()
    |> find_shortest_path()
    |> elem(1)
  end

  def two(input) do
    input
    |> parse_two()
    |> Enum.map(&map_key_distances/1)
    |> two_find_shortest_path()
    |> elem(1)
  end

  defp parse_two(string) do
    string
    |> replace_entrance()
    |> split_maps()
    |> Enum.map(&parse/1)
  end

  defp replace_entrance(string) do
    {x, y} =
      string
      |> String.split("\n")
      |> Enum.map(&String.to_charlist/1)
      |> Enum.with_index()
      |> Enum.find_value(fn {line, j} ->
        i = Enum.find_index(line, &(&1 == ?@))
        if i, do: {i, j}, else: nil
      end)
    replaced =
      string
      |> String.split("\n")
      |> Enum.map(&String.to_charlist/1)
      |> Enum.with_index()
      |> Enum.map(fn {line, j} ->
        cond do
          j == y - 1 || j == y + 1 ->
            line
            |> Enum.with_index()
            |> Enum.map(fn {char, i} -> 
              cond do
                i == x - 1 || i == x + 1 -> ?@
                i == x -> ?#
                true -> char
              end
            end)
          j == y ->
            line
            |> Enum.with_index()
            |> Enum.map(fn {char, i} ->
              cond do
                i == x - 1 || i == x || i == x + 1 -> ?#
                true -> char
              end
            end)
          true ->
            line
        end
      end)
      |> Enum.join("\n")
    {replaced, {x, y}}
  end

  defp split_maps({string, {x, y}}) do
    map1 =
      string
      |> String.split("\n")
      |> Enum.map(&String.to_charlist/1)
      |> Enum.slice(0..y)
      |> Enum.map(fn line -> Enum.slice(line, 0..x) end)
      |> Enum.join("\n")
    map2 =
      string
      |> String.split("\n")
      |> Enum.map(&String.to_charlist/1)
      |> Enum.slice(0..y)
      |> Enum.map(fn line -> Enum.slice(line, x..-1) end)
      |> Enum.join("\n")
    map3 =
      string
      |> String.split("\n")
      |> Enum.map(&String.to_charlist/1)
      |> Enum.slice(y..-1)
      |> Enum.map(fn line -> Enum.slice(line, 0..x) end)
      |> Enum.join("\n")
    map4 =
      string
      |> String.split("\n")
      |> Enum.map(&String.to_charlist/1)
      |> Enum.slice(y..-1)
      |> Enum.map(fn line -> Enum.slice(line, x..-1) end)
      |> Enum.join("\n")
    [map1, map2, map3, map4]
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
      key_distance_list = calculate_key_distances(map, pos)
      {key, key_distance_list}
    end)
    |> Enum.into(%{})
  end

  defp calculate_key_distances(map, pos) do
    calculate_key_distances(map, pos, [], MapSet.new(), MapSet.new(), 0)
    |> Enum.uniq()
    |> Enum.group_by(fn {key, %{required: required}} ->
      {key, required}
    end)
    |> Enum.map(fn {_, list} ->
      Enum.min_by(list, fn {_, %{distance: distance}} -> distance end)
    end)
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

  defp two_find_shortest_path(distance_maps) do
    try_stack =
      distance_maps
      |> Enum.with_index()
      |> Enum.map(fn {distance_map, i} ->
        distance_map
        |> Map.get("@")
        |> Enum.filter(fn {_key, %{required: required_keys}} ->
          MapSet.size(required_keys) == 0
        end)
        |> Enum.map(fn {key, %{distance: distance}} ->
          current_pos = List.replace_at(["@", "@", "@", "@"], i, key)
          {[key], current_pos, distance}
        end)
      end)
      |> List.flatten()
    memos = %{}
    key_count =
      distance_maps
      |> Enum.map(&(map_size(&1) - 1))
      |> Enum.sum
    two_find_shortest_path(distance_maps, try_stack, {nil, nil, nil}, memos, key_count)
  end

  defp two_find_shortest_path(_distance_maps, [], {order, _pos, distance}, _memos, _key_count),
    do: {Enum.reverse(order), distance}
  defp two_find_shortest_path(distance_maps, [{obtained_keys, _pos, current_distance} = new_shortest | rest],
    {_, _, shortest_distance}, memos, key_count)
    when length(obtained_keys) == key_count and current_distance < shortest_distance do
    two_find_shortest_path(distance_maps, rest, new_shortest, memos, key_count)    
  end
  defp two_find_shortest_path(distance_maps,
    [{obtained_keys, current_pos, current_distance} | rest],
    {_, _, shortest_distance} = current_shortest, memos, key_count) do
    obtained_keys_mapset = MapSet.new(obtained_keys)
    {memo_has_shorter?, new_memos} =
      if current_distance >= memos[current_pos][obtained_keys_mapset] do
        {true, memos}
      else
        new_memo =
          Map.update(memos, current_pos,
            %{obtained_keys_mapset => current_distance},
            &(Map.put(&1, obtained_keys_mapset, current_distance))
          )
        {false, new_memo}
      end
    if memo_has_shorter? || shortest_distance && current_distance >= shortest_distance do
      two_find_shortest_path(distance_maps, rest, current_shortest, new_memos, key_count)
    else
      stack_additions =
        distance_maps
        |> Enum.with_index()
        |> Enum.map(fn {distance_map, i} ->
          distance_map
          |> Map.get(Enum.at(current_pos, i))
          |> Keyword.drop(obtained_keys) # remaining keys
          |> Enum.filter(fn {_key, %{required: required_keys}} -> # accessible_keys
            MapSet.subset?(required_keys, MapSet.new(obtained_keys))
          end)
          |> Enum.group_by(fn {key, _} -> key end)
          |> Enum.map(fn {_, list} ->
            Enum.min_by(list, fn {_, %{distance: distance}} -> distance end)
          end)
          |> Enum.map(fn {key, %{distance: distance}} ->
            {
              [key | obtained_keys],
              List.replace_at(current_pos, i, key),
              distance + current_distance
            }
          end)
        end)
        |> List.flatten()
      two_find_shortest_path(distance_maps, stack_additions ++ rest,
        current_shortest, new_memos, key_count)
    end    
  end

  defp find_shortest_path(distance_map) do
    try_stack =
      distance_map
      |> Map.get("@")
      |> Enum.filter(fn {_key, %{required: required_keys}} ->
        MapSet.size(required_keys) == 0
      end)
      |> Enum.map(fn {key, %{distance: distance}} ->
        {[key], distance}
      end)
    memos =
      distance_map
      |> Map.delete("@")
      |> Map.keys()
      |> Enum.map(&({&1, %{}}))
      |> Enum.into(%{})
    key_count = map_size(distance_map) - 1
    find_shortest_path(distance_map, try_stack, {nil, nil}, memos, key_count)
  end

  defp find_shortest_path(_distance_map, [], {order, distance}, _memos, _key_count),
    do: {Enum.reverse(order), distance}
  defp find_shortest_path(distance_map, [{obtained_keys, current_distance} = new_shortest | rest],
    {_, shortest_distance}, memos, key_count)
    when length(obtained_keys) == key_count and current_distance < shortest_distance do
    find_shortest_path(distance_map, rest, new_shortest, memos, key_count)
  end
  defp find_shortest_path(distance_map,
    [{[current_key | _] = obtained_keys, current_distance} | rest],
    {_, shortest_distance} = current_shortest, memos, key_count) do
    obtained_keys_mapset = MapSet.new(obtained_keys)
    {memo_has_shorter?, new_memos} =
      cond do
        memos[current_key][obtained_keys_mapset] && current_distance >= memos[current_key][obtained_keys_mapset] ->
          {true, memos}
        true ->
          {false, put_in(memos, [current_key, obtained_keys_mapset], current_distance)}
      end
    if memo_has_shorter? || shortest_distance && current_distance >= shortest_distance do
      find_shortest_path(distance_map, rest, current_shortest, new_memos, key_count)
    else
      stack_additions =
        distance_map
        |> Map.get(current_key)
        |> Keyword.drop(obtained_keys) # remaining keys
        |> Enum.filter(fn {_key, %{required: required_keys}} -> # accessible_keys
          MapSet.subset?(required_keys, MapSet.new(obtained_keys))
        end)
        |> Enum.group_by(fn {key, _} -> key end)
        |> Enum.map(fn {_, list} ->
          Enum.min_by(list, fn {_, %{distance: distance}} -> distance end)
        end)
        |> Enum.map(fn {key, %{distance: distance}} ->
          {[key | obtained_keys], distance + current_distance}
        end)
      find_shortest_path(distance_map, stack_additions ++ rest, current_shortest, new_memos, key_count)
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

Eighteen.one(input)
|> IO.inspect

Eighteen.two(input)
|> IO.inspect