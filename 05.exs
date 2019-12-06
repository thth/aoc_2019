defmodule Five do
  @input_one [1]
  @input_two [5]

  def one(input) do
    {_intcode, outputs} =
      input
      |> parse()
      |> run(@input_one)   
    outputs
    |> Enum.at(-1)
  end

  def two(input) do
    {_intcode, outputs} =
      input
      |> parse()
      |> run(@input_two)
    outputs
    |> Enum.at(0)
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end

  def run(intcode, inputs, outputs \\ [], i \\ 0) do
    {opcode, param_modes} = parse_opcode(Enum.at(intcode, i))
    if opcode == 99 do
      {intcode, outputs}
    else
      case opcode do
        1 ->
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          pos = Enum.at(intcode, i + 3)
          sum = a + b
          new_intcode = List.replace_at(intcode, pos, sum)
          run(new_intcode, inputs, outputs, i + 4)
        2 ->
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          pos = Enum.at(intcode, i + 3)
          product = a * b
          new_intcode = List.replace_at(intcode, pos, product)
          run(new_intcode, inputs, outputs, i + 4)
        3 ->
          total_codes = 2
          {input, new_inputs} = List.pop_at(inputs, 0)
          pos = Enum.at(intcode, i + 1)
          new_intcode = List.replace_at(intcode, pos, input)
          run(new_intcode, new_inputs, outputs, i + total_codes)
        4 ->
          total_codes = 2
          output_pos = Enum.at(intcode, i + 1)
          output = Enum.at(intcode, output_pos)
          new_outputs = outputs ++ [output]
          run(intcode, inputs, new_outputs, i + total_codes)
        5 ->
          total_codes = 3
          true? = get_value(intcode, param_modes, i, 0) != 0
          new_i = if true?, do: get_value(intcode, param_modes, i, 1), else: i + total_codes
          run(intcode, inputs, outputs, new_i)
        6 ->
          total_codes = 3
          false? = get_value(intcode, param_modes, i, 0) == 0
          new_i = if false?, do: get_value(intcode, param_modes, i, 1), else: i + total_codes
          run(intcode, inputs, outputs, new_i)
        7 ->
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          result = if (a < b), do: 1, else: 0
          pos = Enum.at(intcode, i + 3)
          new_intcode = List.replace_at(intcode, pos, result)
          run(new_intcode, inputs, outputs, i + 4)
        8 ->
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          result = if (a == b), do: 1, else: 0
          pos = Enum.at(intcode, i + 3)
          new_intcode = List.replace_at(intcode, pos, result)
          run(new_intcode, inputs, outputs, i + 4)
      end
    end
  end

  def get_value(intcode, param_modes, i, param_number) do
    param_mode = Enum.at(param_modes, param_number, 0)
    case param_mode do
      1 -> # immediate
        Enum.at(intcode, i + param_number + 1)
      0 -> # position
        Enum.at(intcode, 225)
        Enum.at(intcode, Enum.at(intcode, i + param_number + 1))
    end
  end

  def get_param_mode(param_modes, i) do
    Enum.fetch(param_modes, i) || 0
  end

  def parse_opcode(n) do
    full_code =
      n
      |> Integer.to_string()
      |> String.pad_leading(2, "0")
      |> String.to_charlist()
    opcode =
      full_code
      |> Enum.slice(-2, 2)
      |> List.to_integer()
    parameters =
      full_code
      |> Enum.slice(0..-3)
      |> Enum.reverse()
      |> List.to_string()
      |> String.graphemes()
      |> Enum.map(&String.to_integer/1)
    {opcode, parameters}
  end
end

input = File.read!("input/05.txt")

Five.one(input)
|> IO.inspect

Five.two(input)
|> IO.inspect
