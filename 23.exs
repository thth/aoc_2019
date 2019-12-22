defmodule TwentyThree do
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

input = File.read!("input/23.txt")

TwentyThree.one(input)
|> IO.inspect

TwentyThree.two(input)
|> IO.inspect
