defmodule Twelve do
  defmodule Moon do
    defstruct x: nil, y: nil, z: nil, xv: 0, yv: 0, zv: 0
  end

  @number_of_steps 1000

  def one(input) do
    input
    |> parse()
    |> step_until(@number_of_steps)
    |> Enum.map(&calculate_energy/1)
    |> Enum.sum()
  end

  def two(input) do
    input
    |> parse()
    |> loop_until_axis_periods()
    |> Enum.reduce(fn x, acc -> lcm(x, acc) end)
  end

  def parse(raw) do
    regex = ~r/^.+x=(?<x>-?\d+).+y=(?<y>-?\d+).+z=(?<z>-?\d+)>$/
    raw
    |> String.trim()
    |> String.split("\n")
    |> Stream.map(&(Regex.named_captures(regex, &1)))
    |> Enum.map(fn %{"x" => x, "y" => y, "z" => z} ->
      %Moon{
        x: String.to_integer(x),
        y: String.to_integer(y),
        z: String.to_integer(z)
      }
    end)
  end

  defp loop_until_axis_periods(moon_list) do
    empty_list_for_each_moon =
      1..length(moon_list)
      |> Enum.map(fn _ -> [] end)
    axis_state_repeats_map =
      %{
        x: empty_list_for_each_moon,
        y: empty_list_for_each_moon,
        z: empty_list_for_each_moon
      }
    loop_until_axis_periods(moon_list, moon_list, axis_state_repeats_map)
  end

  defp loop_until_axis_periods(original, moon_list, step \\ 0, repeats_map) do
    if Enum.all?(repeats_map, fn {_axis, moons_repeats} -> find_period(moons_repeats) end) do
      Enum.map(repeats_map, fn {_axis, moons_repeats} -> find_period(moons_repeats) end)
    else
      new_moon_list =
        moon_list
        |> update_velocity()
        |> update_position()

      new_repeats_map =
        repeats_map
        |> Enum.map(fn {axis, moons_repeats} ->
          new_moons_repeats =
            moons_repeats
            |> Enum.with_index()
            |> Enum.map(fn {moon_repeats, i} ->
              original_moon = Enum.at(original, i)
              new_moon = Enum.at(new_moon_list, i)
              if axis_same?(original_moon, new_moon, axis) do
                moon_repeats ++ [step + 1]
              else
                moon_repeats
              end
            end)
          {axis, new_moons_repeats}
        end)
        |> Enum.into(%{})
      loop_until_axis_periods(original, new_moon_list, step + 1, new_repeats_map)
    end
  end

  defp find_period([moon_repeats | rest_repeats]) do
    moon_repeats
    |> Enum.find(fn repeat ->
      rest_repeats
      |> Enum.all?(fn checked_moon_repeats ->
        Enum.find(checked_moon_repeats, &(&1 == repeat))
      end)
    end)
  end

  defp axis_same?(original, new, axis) do
    (
      Map.get(original, axis) == Map.get(new, axis)
      and
      Map.get(new, append_v(axis)) == 0
    )
  end

  defp append_v(atom) do
    String.to_atom(to_string(atom) <> "v")
  end

  defp step_until(moon_list, step \\ 0, final_step)
  defp step_until(moon_list, step, final_step) when step == final_step, do: moon_list
  defp step_until(moon_list, step, final_step) do
    new_moon_list =
      moon_list
      |> update_velocity()
      |> update_position()
    step_until(new_moon_list, step + 1, final_step)
  end

  defp update_velocity(moon_list) do
    Enum.map(moon_list, fn %Moon{x: x, y: y, z: z, xv: xv, yv: yv, zv: zv} = moon ->
      {dxv, dyv, dzv} =
        Enum.reduce(moon_list, {0,0,0}, fn %Moon{x: i, y: j, z: k}, {ax, ay, az} ->
          inc_x = calculate_gravity(x, i)
          inc_y = calculate_gravity(y, j) 
          inc_z = calculate_gravity(z, k)
          {ax + inc_x, ay + inc_y, az + inc_z}
        end)
      %Moon{moon | xv: xv + dxv, yv: yv + dyv, zv: zv + dzv}
    end)
  end

  defp calculate_gravity(a, b) do
    cond do
      b > a -> 1
      b < a -> -1
      true -> 0
    end
  end

  defp update_position(moon_list) do
    Enum.map(moon_list, fn %Moon{x: x, y: y, z: z, xv: xv, yv: yv, zv: zv} = moon ->
      %Moon{moon | x: x + xv, y: y + yv, z: z + zv}
    end)
  end

  defp calculate_energy(%Moon{x: x, y: y, z: z, xv: xv, yv: yv, zv: zv}) do
    (abs(x) + abs(y) + abs(z)) * (abs(xv) + abs(yv) + abs(zv))
  end

  # miiiiiiiight be copy pasted
  defp lcm(a, b), do: div(abs(a * b), gcd(a, b))
  defp gcd(a, 0), do: abs(a)
  defp gcd(a, b), do: gcd(b, rem(a, b))
end

input = File.read!("input/12.txt")

Twelve.one(input)
|> IO.inspect

Twelve.two(input)
|> IO.inspect
