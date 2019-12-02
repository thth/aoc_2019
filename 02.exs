defmodule Two do
  @desired_output 19690720

  def one(input) do
    input
    |> parse()
    |> List.replace_at(1, 12)
    |> List.replace_at(2, 2)
    |> run()
    |> Enum.at(0)
  end

  def two(input) do
    input
    |> parse()
    |> find_output()
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end

  def run(intcode, i \\ 0) do
    opcode = Enum.at(intcode, i)
    if opcode == 99 do
      intcode
    else
      a = Enum.at(intcode, Enum.at(intcode, i + 1))
      b = Enum.at(intcode, Enum.at(intcode, i + 2))
      pos = Enum.at(intcode, i + 3)
      case opcode do
        1 ->
          sum = a + b
          new_intcode = List.replace_at(intcode, pos, sum)
          run(new_intcode, i + 4)
        2 ->
          product = a * b
          new_intcode = List.replace_at(intcode, pos, product)
          run(new_intcode, i + 4)
      end
    end
  end

  def replace_and_get_output(intcode, noun, verb) do
    intcode
    |> List.replace_at(1, noun)
    |> List.replace_at(2, verb)
    |> run()
    |> Enum.at(0)
  end

  def find_output(intcode, noun \\ 0, verb \\ 0) do
    max_address = length(intcode) - 1
    output = replace_and_get_output(intcode, noun, verb)
    cond do
      output == @desired_output ->
        (100 * noun) + verb
      verb >= max_address and noun >= max_address ->
        :not_found
      verb >= max_address ->
        find_output(intcode, noun + 1, 0)
      true ->
        find_output(intcode, noun, verb + 1)
    end
  end
end

input = File.read!("input/02.txt")

Two.one(input)
|> IO.inspect

Two.two(input)
|> IO.inspect