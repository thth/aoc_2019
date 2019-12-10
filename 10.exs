defmodule Ten do
  @asteroid_number 200

  def one(input) do
    input
    |> parse()
    |> create_map_of_stations_angle_maps()
    |> find_station_with_most_asteroids()
    |> (fn {_station, angle_map} ->
      angle_map
      |> Map.keys()
      |> length()
    end).()
  end

  def two(input) do
    {station, angle_map} =
      input
      |> parse()
      |> create_map_of_stations_angle_maps()
      |> find_station_with_most_asteroids()

    angle_map
    |> Stream.map(fn {angle, asteroids} ->
      {angle, sort_asteroids_by_closest(station, asteroids)}
    end)
    |> Enum.sort(fn {a_angle, _}, {b_angle, _} ->
      angle_less_than?(a_angle, b_angle)
    end)
    |> zap_until(@asteroid_number)
    |> (fn {x, y} -> x * 100 + y end).()
  end

  def parse(raw) do
    raw
    |> String.split("\n")
    |> Enum.with_index()
    |> Enum.reduce(MapSet.new(), fn {row, y}, mapset ->
      row
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.reduce(mapset, fn {symbol, x}, acc ->
        case symbol do
          "." -> acc
          "#" -> MapSet.put(acc, {x, y})
        end
      end)
    end)
  end

  defp create_map_of_stations_angle_maps(asteroid_mapset) do
    asteroid_mapset
    |> Enum.map(fn station ->
      angle_map = map_asteroid_angles(asteroid_mapset, station)
      {station, angle_map}
    end)
    |> Enum.into(%{})
  end

  defp map_asteroid_angles(mapset, station) do
    Enum.reduce(mapset, %{}, fn asteroid, acc ->
      if station == asteroid do
        acc
      else
        angle = calculate_angle(station, asteroid)
        Map.update(acc, angle, [asteroid], &([asteroid | &1]))
      end
    end)
  end

  defp calculate_angle({station_x, station_y}, {asteroid_x, asteroid_y}) do
    x_diff = asteroid_x - station_x
    y_diff = asteroid_y - station_y
    cond do
      x_diff == 0 and y_diff > 0 -> {0, 1}
      x_diff == 0 and y_diff < 0 -> {0, -1}
      x_diff > 0 -> {1, Float.round(y_diff / abs(x_diff), 8)}
      x_diff < 0 -> {-1, Float.round(y_diff / abs(x_diff), 8)}
    end
  end

  defp find_station_with_most_asteroids(map_of_station_angle_maps) do
    map_of_station_angle_maps
    |> Enum.max_by(fn {_station, angle_map} ->
      angle_map
      |> Map.keys()
      |> length()
    end)
  end

  defp angle_less_than?({a_x, a_y} = a_angle, {b_x, b_y} = b_angle) do
    cond do
      a_angle == {0, -1} -> true
      b_angle == {0, -1} -> false
      a_x == 1 and b_x == -1 -> true
      a_x == -1 and b_x == 1 -> false
      a_angle == {0, 1} and b_x == 1 -> false
      a_angle == {0, 1} and b_x == -1 -> true
      a_x == 1 and b_x == 1 -> a_y < b_y
      a_x == -1 and b_x == -1 -> a_y > b_y
      b_angle == {0, 1} and a_x == 1 -> true
      b_angle == {0, 1} and a_x == -1 -> false
      true -> :error
    end
  end

  def sort_asteroids_by_closest(station, asteroid_list) do
    Enum.sort(asteroid_list, fn a, b ->
      manhattan_distance(station, a) < manhattan_distance(station, b)
    end)
  end
  
  defp manhattan_distance({s_x, s_y}, {a_x, a_y}) do
    abs(a_x - s_x) + abs(a_y - s_y) 
  end

  defp zap_until(sorted_angle_list, target) do
    [{current_angle, _} | _] = sorted_angle_list
    zap_until(sorted_angle_list, target, current_angle)
  end
  defp zap_until(angle_list, target, current_angle, last_zapped \\ nil, i \\ 0)
  defp zap_until(_, target, _, last_zapped, i) when target == i, do: last_zapped
  defp zap_until([], _target, _current_angle, _last_zapped, _i), do: nil
  defp zap_until(angle_list, target, current_angle, _last_zapped, i) do
    {_, [new_zapped | new_asteroids]} = List.keyfind(angle_list, current_angle, 0)
    next_angle = find_next_angle(angle_list, current_angle)
    new_angle_list =
      case new_asteroids do
        [] -> List.keydelete(angle_list, current_angle, 0)
        _ -> List.keyreplace(angle_list, current_angle, 0, {current_angle, new_asteroids})
      end
    zap_until(new_angle_list, target, next_angle, new_zapped, i + 1)
  end

  defp find_next_angle(angle_list, current_angle) do
    current_index = Enum.find_index(angle_list, fn {angle, _} ->
      angle == current_angle
    end)
    next_index =
      if length(angle_list) == current_index + 1,
        do: 0,
        else: current_index + 1
    angle_list
    |> Enum.at(next_index)
    |> elem(0)
  end
end

input = File.read!("input/10.txt")

Ten.one(input)
|> IO.inspect

Ten.two(input)
|> IO.inspect
