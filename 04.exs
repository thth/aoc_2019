defmodule Four do
  def one(input) do
    input
    |> parse()
    |> Enum.count(&check_valid?/1)
  end

  def two(input) do
    input
    |> parse()
    |> Enum.count(&check_valid_two?/1)
  end

  def parse(raw) do
    {a, b} =
      raw
      |> String.split("-")
      |> Enum.map(&String.to_integer/1)
      |> List.to_tuple()
    a..b
  end

  def check_valid?(n) do
    check_ascending?(n) && check_adjacent?(n)
  end

  def check_ascending?(n) do
    sorted =
      n
      |> Integer.to_charlist()
      |> Enum.sort()
      |> List.to_integer()
    n == sorted
  end

  def check_adjacent?(n) do
    dedup =
      n
      |> Integer.digits()
      |> Enum.dedup()
    length(Integer.digits(n)) != length(dedup)
  end

  def check_valid_two?(n) do
    check_valid?(n) && check_two?(n)
  end

  def check_two?(n) do
    n
    |> Integer.digits()
    |> Enum.chunk_by(&(&1))
    |> Enum.any?(&(length(&1) == 2))
  end
end

input = File.read!("input/04.txt")

Four.one(input)
|> IO.inspect

Four.two(input)
|> IO.inspect
