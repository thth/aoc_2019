defmodule TwentyFive do
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

input = File.read!("input/25.txt")

TwentyFive.one(input)
|> IO.inspect

TwentyFive.two(input)
|> IO.inspect
