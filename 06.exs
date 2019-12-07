defmodule Six do
  @satellite_a "YOU" 
  @satellite_b "SAN"

  def one(input) do
    input
    |> parse()
    |> count_orbits()
  end

  def two(input) do
    input
    |> parse()
    |> calculate_distance_between_satellites(@satellite_a, @satellite_b)
  end

  def parse(raw) do
    raw
    |> String.trim()
    |> String.split("\n")
    |> Stream.map(&(String.split(&1, ")")))
    |> Enum.into(%{}, fn [body, satellite] -> {satellite, body} end)
  end

  def count_orbits(orbit_map) do
    [first_satellite | rest_queue] = Map.keys(orbit_map)
    count_orbits(orbit_map, rest_queue, first_satellite)
  end

  def count_orbits(orbit_map, satellite_queue, current, orbit_count \\ 0)
  def count_orbits(_orbit_map, [], "COM", orbit_count), do: orbit_count
  def count_orbits(orbit_map, [next_satellite | rest_queue], "COM", orbit_count), do:
    count_orbits(orbit_map, rest_queue, next_satellite, orbit_count)
  def count_orbits(orbit_map, satellite_queue, current, orbit_count) do
    next_current = Map.get(orbit_map, current)
    count_orbits(orbit_map, satellite_queue, next_current, orbit_count + 1)
  end
  
  def calculate_distance_between_satellites(orbit_map, satellite_a, satellite_b) do
    a_ancestors = list_ancestors(orbit_map, satellite_a)
    b_ancestors = list_ancestors(orbit_map, satellite_b)
    closest_ancestor = find_closest_ancestor(a_ancestors, b_ancestors)
    Kernel.+(
      distance_to_ancestor(a_ancestors, closest_ancestor),
      distance_to_ancestor(b_ancestors, closest_ancestor)
    )
  end

  def list_ancestors(orbit_map, satellite, ancestors \\ [])
  def list_ancestors(_orbit_map, "COM", ancestors), do: ancestors ++ ["COM"]
  def list_ancestors(orbit_map, satellite, ancestors) do
    parent = Map.get(orbit_map, satellite)
    list_ancestors(orbit_map, parent, ancestors ++ [parent])
  end

  def find_closest_ancestor([], _b_ancestors), do: nil
  def find_closest_ancestor([a | a_rest], b_ancestors) do
    case Enum.find(b_ancestors, &(&1 == a)) do
      nil -> find_closest_ancestor(a_rest, b_ancestors)
      closest_ancestor -> closest_ancestor
    end
  end

  def distance_to_ancestor(ancestor_list, ancestor) do
    Enum.find_index(ancestor_list, &(&1 == ancestor))
  end
end

input = File.read!("input/06.txt")

Six.one(input)
|> IO.inspect

Six.two(input)
|> IO.inspect
