defmodule TwentyFour do
  def one(input) do
    input
    |> parse()
  end

  def two(input) do
    input
    |> parse()
  end

  def parse(raw) do
    raw
  end
end

input = File.read!("input/24.txt")

TwentyFour.one(input)
|> IO.inspect

TwentyFour.two(input)
|> IO.inspect
