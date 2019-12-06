defmodule Six do
  def one(input) do
    input
    |> parse()
    |> count_orbits()
  end

  def two(input) do
    orbit_map =
      input
      |> parse()
    you_ancestors = list_ancestors(orbit_map, "YOU")
    san_ancestors = list_ancestors(orbit_map, "SAN")
    closest_ancestor = find_closest_ancestor(you_ancestors, san_ancestors)
    Kernel.+(
      distance_to_ancestor(you_ancestors, closest_ancestor),
      distance_to_ancestor(san_ancestors, closest_ancestor)
    )
  end

  def parse(raw) do
    raw
    |> String.trim()
    |> String.split("\n")
    |> Stream.map(&(String.split(&1, ")")))
    |> Enum.map(&List.to_tuple/1)
    |> Enum.into(%{}, fn {orbitee, orbiter} -> {orbiter, orbitee} end)
  end

  def count_orbits(orbit_map) do
    satellites = Map.keys(orbit_map)
    count_orbits(orbit_map, satellites)
  end

  def count_orbits(orbit_map, satellites, current \\ nil, orbits \\ 0)
  def count_orbits(_orbit_map, [_satellite | []], "COM", orbits), do: orbits
  def count_orbits(orbit_map, [_satellite | rest], "COM", orbits) do
    count_orbits(orbit_map, rest, nil, orbits)
  end
  def count_orbits(orbit_map, satellites = [satellite | _rest], nil, orbits) do
      next = Map.get(orbit_map, satellite)
      count_orbits(orbit_map, satellites, next, orbits + 1)
  end
  def count_orbits(orbit_map, satellites, current, orbits) do
    next = Map.get(orbit_map, current)
    count_orbits(orbit_map, satellites, next, orbits + 1)
  end
  
  def list_ancestors(orbit_map, satellite, ancestors \\ [])
  def list_ancestors(_orbit_map, "COM", ancestors), do: ancestors ++ ["COM"]
  def list_ancestors(orbit_map, satellite, ancestors) do
    parent = Map.get(orbit_map, satellite)
    list_ancestors(orbit_map, parent, ancestors ++ [parent])
  end

  def find_closest_ancestor(a, b), do: find_closest_ancestor(a, b, a)
  def find_closest_ancestor([a | _a_rest], [ b | _b_rest], _a_original) when a == b, do: a
  def find_closest_ancestor([_a | []], [_b | b_rest], a_original),
    do: find_closest_ancestor(a_original, b_rest, a_original)
  def find_closest_ancestor([_a | a_rest], b_ancestors, a_original) do
    find_closest_ancestor(a_rest, b_ancestors, a_original)
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
