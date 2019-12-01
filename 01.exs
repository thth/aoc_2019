defmodule One do
  def one(input) do
    input
    |> Stream.map(&calculate_fuel/1)
    |> Enum.reduce(&+/2)
  end

  def two(input) do
    input
    |> Stream.map(&calculate_total_fuel/1)
    |> Enum.reduce(&+/2)
  end

  defp calculate_fuel(mass) do
    fuel =
      mass
      |> Kernel./(3)
      |> Kernel.trunc()
      |> Kernel.-(2)
    if fuel <= 0, do: 0, else: fuel
  end

  defp calculate_total_fuel(acc \\ 0, mass)
  defp calculate_total_fuel(acc, 0), do: acc
  defp calculate_total_fuel(acc, mass) do
    fuel = calculate_fuel(mass)
    calculate_total_fuel(acc + fuel, fuel)
  end
end

raw = File.read!("input/01.txt")
input =
  raw
  |> String.split("\n")
  |> Enum.map(&String.to_integer/1)

One.one(input)
|> IO.inspect

One.two(input)
|> IO.inspect