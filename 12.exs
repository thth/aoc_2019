defmodule Twelve do
  defmodule Moon do
    defstruct x: nil, y: nil, z: nil, xv: 0, yv: 0, zv: 0
  end

  # defmodule Period do
  #   defstruct [:x, :y, :z, :xv, :yv, :zv]
  # end
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
    # |> find_all_axis_periods()
    |> find_axis_periods()
    # |> find_zero_energies()
    # |> step_until_same()
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

  defp find_all_axis_periods(moon_list) do
    periods = [x: nil, y: nil, z: nil]
    find_all_axis_periods(moon_list, moon_list, periods)
  end
  defp find_all_axis_periods(original, moon_list, step \\ 0, periods) do
    if Enum.all?(periods, fn {_k, v} -> v end) do
      periods
    else
      new_moon_list =
        moon_list
        |> update_velocity()
        |> update_position()

      new_periods =
        periods
        |> Enum.map(fn {axis, n} ->
          if n == nil and all_axis_same?(original, new_moon_list, axis) do
            {axis, step + 1}
          else
            {axis, nil}
          end
        end)

      find_all_axis_periods(original, new_moon_list, step + 1, new_periods)
    end
  end

  defp all_axis_same?(original, new, axis) do
    Enum.zip(original, new)
    |> Enum.all?(fn {original_moon, new_moon} ->
      (
        Map.get(new_moon, axis) == Map.get(original_moon, axis)
        and
        Map.get(new_moon, ptv(axis)) == 0
      )
    end)
  end

  # defp find_axis_periods(moon_list) do
  #   periods =
  #     1..length(moon_list)
  #     # |> Enum.map(fn _ -> %{x: nil, y: nil, z: nil, vx: nil, vy: nil, vz: nil} end)
  #     |> Enum.map(fn _ -> %{x: nil, y: nil, z: nil} end)
  #   find_axis_periods(moon_list, moon_list, periods)
  # end

  defp find_axis_periods(moon_list) do
    periods =
      1..length(moon_list)
      |> Enum.map(fn _ -> %{x: [], y: [], z: []} end)
    find_axis_periods(moon_list, moon_list, periods)
  end

  defp find_axis_periods(original, moon_list, step \\ 0, periods) do
    if Enum.all?(periods, fn period ->
      Enum.all?(period, fn {_k, v} -> length(v) >= 20 end)
    end) do
      periods
    else
      new_moon_list =
        moon_list
        |> update_velocity()
        |> update_position()

      new_periods =
        periods
        |> Enum.with_index()
        |> Enum.map(fn {period, i} ->
          period
          |> Enum.map(fn {k, v} ->
            original_moon = Enum.at(original, i)
            new_moon = Enum.at(new_moon_list, i)
            if length(v) < 20 and axis_same?(original_moon, new_moon, k) do
              {k, v ++ [step + 1]}
            else
              {k, v}
            end
            # if v do
            #   {k, v}
            # else
            #   original_moon = Enum.at(original, i)
            #   new_moon = Enum.at(new_moon_list, i)
            #   new_v =
            #      if Map.get(original_moon, k) == Map.get(new_moon, k)
            #        and Map.get(new_moon, ptv(k)) == 0 do
            #        step + 1
            #      else
            #       nil
            #      end
            #   {k, new_v}
            # end
          end)
          |> Enum.into(%{})
        end)
      find_axis_periods(original, new_moon_list, step + 1, new_periods)
    end
  end

  defp axis_same?(original, new, axis) do
    (
      Map.get(original, axis) == Map.get(new, axis)
      and
      Map.get(new, ptv(axis)) == 0
    )
  end

  # defp find_periods(moon_list) do
  #   periods =
  #     1..length(moon_list)
  #     |> Enum.map(fn _ -> nil end)
  #   find_periods(moon_list, moon_list, periods)
  # end

  # defp find_periods(original, moon_list, step \\ 0, periods) do
  #   if Enum.all?(periods, &(&1)) do
  #     periods
  #   else
  #     new_moon_list =
  #       moon_list
  #       |> update_velocity()
  #       |> update_position()
  #     in_original_pos? =
  #       new_moon_list
  #       |> Enum.with_index()
  #       |> Enum.map(fn {%Moon{x: x, y: y, z: z}, i} ->
  #         %Moon{x: ox, y: oy, z: oz} = Enum.at(original, i)
  #         x == ox and y == oy and z == oz
  #       end)
  #     new_periods =
  #       periods
  #       |> Enum.with_index()
  #       |> Enum.map(fn {period, i} ->
  #         if (Enum.at(in_original_pos?, i)) and (Enum.at(periods, i) == nil) do
  #           step + 1
  #         else
  #           period
  #         end
  #       end)
  #     find_periods(original, new_moon_list, step + 1, new_periods)
  #   end
  # end

  defp ptv (atom) do
    String.to_atom(to_string(atom) <> "v")
  end

  ###### energy meme
  # defp find_zero_energies(moon_list) do
  #   zeros =
  #     1..length(moon_list)
  #     |> Enum.map(fn _ -> [] end)
  #   find_zero_energies(moon_list, zeros)
  # end

  # defp find_zero_energies(moon_list, step \\ 0, zeros) do
  #   # if Enum.all?(zeros, &(length(&1) >= 5)) do
  #   if Enum.all?(zeros, &(length(&1) >= 10)) do
  #     zeros
  #   else
  #     new_moon_list =
  #       moon_list
  #       |> update_velocity()
  #       |> update_position()
  #     energies = Enum.map(new_moon_list, &calculate_energy/1)
  #     new_zeros = update_zeros(zeros, energies, step + 1)
  #     find_zero_energies(new_moon_list, step + 1, new_zeros)
  #   end
  # end

  # defp update_zeros(zeros, energies, step) do
  #   zeros
  #   |> Enum.with_index()
  #   |> Enum.map(fn {list, i} ->
  #     if length(list) >= 10 do
  #       list
  #     else
  #       if Enum.at(energies, i) == 0, do: list ++ [step], else: list
  #     end
  #   end)
  # end
  ##### end energy meme

  # defp step_until_same(moon_list), do: step_until_same(moon_list, moon_list)

  # defp step_until_same(original, moon_list, step \\ 0)
  # defp step_until_same(original, moon_list, step) when original == moon_list and step != 0,
  #   do: step
  # defp step_until_same(original, moon_list, step) do
  #   new_moon_list =
  #     moon_list
  #     |> update_velocity()
  #     |> update_position()
  #   step_until_same(original, new_moon_list, step + 1)
  # end

  defp step_until(moon_list, step \\ 0, final_step)
  defp step_until(moon_list, step, final_step) when step == final_step,
    do: moon_list
  defp step_until(moon_list, step, final_step) do
    # energies = moon_list |> Enum.map(&calculate_energy/1)
    # IO.inspect({energies, Enum.sum(energies)}, label: step, charlists: :as_lists)
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
      b == a -> 0
      true -> -1
    end
  end

  defp update_position(moon_list) do
    Enum.map(moon_list, fn %Moon{x: x, y: y, z: z, xv: xv, yv: yv, zv: zv} = moon ->
      %Moon{moon | x: x + xv, y: y + yv, z: z + zv}
    end)
  end

  def calculate_energy(%Moon{x: x, y: y, z: z, xv: xv, yv: yv, zv: zv}) do
    (abs(x) + abs(y) + abs(z)) * (abs(xv) + abs(yv) + abs(zv))
  end
end

# input =
#   """
#   <x=-1, y=0, z=2>
#   <x=2, y=-10, z=-7>
#   <x=4, y=-8, z=8>
#   <x=3, y=5, z=-1>
#   """
# input =
#   """
#   <x=-8, y=-10, z=0>
#   <x=5, y=5, z=10>
#   <x=2, y=-7, z=3>
#   <x=9, y=-8, z=-3>
#   """
input = File.read!("input/12.txt")

# Twelve.one(input)
# |> IO.inspect

Twelve.two(input)
|> IO.inspect(width: 256)
