defmodule Nineteen do
  defmodule Intcode do
    defstruct intcode: nil, inputs: [], outputs: [], pointer: 0,
              relative_base: 0, halted?: false

    def new(list) do
      intcode =
        list
        |> Stream.map(&String.to_integer/1)
        |> Stream.with_index()
        |> Enum.into(%{}, fn {n, i} -> {i, n} end)
      %Intcode{intcode: intcode}
    end

    def input_and_take_all_outputs(state, inputs) do
      state
      |> insert_inputs(inputs)
      |> run_intcode()
      |> take_all_outputs()
    end

    def insert_inputs(state, inputs) do
      %Intcode{state | inputs: state.inputs ++ inputs}
    end

    def take_outputs(state, number \\ 1) do
      {results, rest} = Enum.split(state.outputs, number)
      {results, %Intcode{state | outputs: rest}}
    end

    def take_all_outputs(state) do
      {state.outputs, %Intcode{state | outputs: []}}
    end

    def clear_outputs(state) do
      %Intcode{state | outputs: []}
    end

    def run_intcode(state) do
      case step_intcode(state) do
        {:waiting_for_input, new_state} -> new_state
        {:halt, new_state} -> new_state
        {:continue, new_state} -> run_intcode(new_state)
      end
    end

    def edit_at_address(%Intcode{intcode: intcode} = state, address, value) do
      new_intcode = Map.put(intcode, address, value)
      %Intcode{state | intcode: new_intcode}
    end

    defp step_intcode(%Intcode{
      intcode: intcode,
      inputs: inputs,
      outputs: outputs,
      pointer: pointer,
      relative_base: relative_base
      } = state) do

      [opcode | _param_modes] = ins_modes = parse_opcode(intcode_at(intcode, pointer))

      case opcode do
        99 -> # halt
          {:halt, %Intcode{state | halted?: true}}
        1 -> # sum
          a = get_value(intcode, pointer, relative_base, ins_modes, 1)
          b = get_value(intcode, pointer, relative_base, ins_modes, 2)
          pos = get_address(intcode, pointer, relative_base, ins_modes, 3)
          sum = a + b
          {:continue, %Intcode{state |
            intcode: intcode_insert(intcode, pos, sum),
            pointer: pointer + 4
          }}
        2 -> # product
          a = get_value(intcode, pointer, relative_base, ins_modes, 1)
          b = get_value(intcode, pointer, relative_base, ins_modes, 2)
          pos = get_address(intcode, pointer, relative_base, ins_modes, 3)
          product = a * b
          {:continue, %Intcode{state |
            intcode: intcode_insert(intcode, pos, product),
            pointer: pointer + 4
          }}
        3 -> # insert input
          case inputs do
            [] ->
              {:waiting_for_input, state}
            [input | rest_inputs] ->
              pos = get_address(intcode, pointer, relative_base, ins_modes, 1)
              {:continue, %Intcode{state |
                intcode: intcode_insert(intcode, pos, input),
                inputs: rest_inputs,
                pointer: pointer + 2
              }}
          end
        4 -> # enqueue output
          output = get_value(intcode, pointer, relative_base, ins_modes, 1)
          {:continue, %Intcode{state |
            outputs: outputs ++ [output],
            pointer: pointer + 2
          }}
        5 -> # jump-if-true
          true? = get_value(intcode, pointer, relative_base, ins_modes, 1) != 0
          new_address = if true?,
            do: get_value(intcode, pointer, relative_base, ins_modes, 2),
            else: pointer + 3
          {:continue, %Intcode{state |
            pointer: new_address
          }}
        6 -> # jump-if-false
          false? = get_value(intcode, pointer, relative_base, ins_modes, 1) == 0
          new_address = if false?,
            do: get_value(intcode, pointer, relative_base, ins_modes, 2),
            else: pointer + 3
          {:continue, %Intcode{state |
            pointer: new_address
          }}
        7 -> # less than
          a = get_value(intcode, pointer, relative_base, ins_modes, 1)
          b = get_value(intcode, pointer, relative_base, ins_modes, 2)
          pos = get_address(intcode, pointer, relative_base, ins_modes, 3)
          result = if (a < b), do: 1, else: 0
          {:continue, %Intcode{state |
            intcode: intcode_insert(intcode, pos, result),
            pointer: pointer + 4
          }}
        8 -> # equals
          a = get_value(intcode, pointer, relative_base, ins_modes, 1)
          b = get_value(intcode, pointer, relative_base, ins_modes, 2)
          pos = get_address(intcode, pointer, relative_base, ins_modes, 3)
          result = if (a == b), do: 1, else: 0
          {:continue, %Intcode{state |
            intcode: intcode_insert(intcode, pos, result),
            pointer: pointer + 4
          }}
        9 -> # adjust relative base
          a = get_value(intcode, pointer, relative_base, ins_modes, 1)
          new_relative_base = relative_base + a
          {:continue, %Intcode{state |
            relative_base: new_relative_base,
            pointer: pointer + 2
          }}
      end
    end

    defp intcode_at(intcode, pointer) do
      Map.get(intcode, pointer, 0)
    end

    defp intcode_insert(intcode, pointer, value) do
      Map.put(intcode, pointer, value)
    end

    # output of [opcode | param_modes] referred to as ins_modes in variable names
    defp parse_opcode(n) when n < 100, do: [n]
    defp parse_opcode(n) do
      opcode = rem(n, 100)
      param_modes =
        n
        |> div(100)
        |> Integer.digits()
        |> Enum.reverse()
      [opcode | param_modes]
    end

    defp get_value(intcode, pointer, relative_base, ins_modes, param_index) do
      param_mode = Enum.at(ins_modes, param_index, 0)
      param = intcode_at(intcode, pointer + param_index)

      case param_mode do
        2 -> # relative
          intcode_at(intcode, relative_base + param)
        1 -> # immediate
          param
        0 -> # position
          intcode_at(intcode, param)
      end
    end

    defp get_address(intcode, pointer, relative_base, ins_modes, param_index) do
      param_mode = Enum.at(ins_modes, param_index, 0)
      param = intcode_at(intcode, pointer + param_index)

      case param_mode do
        0 -> # position
          param
        2 -> # relative
          param + relative_base
      end
    end
  end

  @x_max 49
  @y_max 49
  @santa_thicc 100

  def one(input) do
    input
    |> parse()
    |> scan_area(0..@x_max, 0..@y_max)
    |> Enum.reduce(0, fn {_pos, n}, acc ->
      acc + n
    end)
  end

  def two(input) do
    input
    |> parse()
    |> scan_until_big()
    |> two_answer()
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Intcode.new()
  end

  defp two_answer({x, y}) do
    x * 10000 + y
  end

  # noticed there's a gap around y = 1 -> y = 3;
  # take some default values which definitely aren't a terrible solution!
  defp scan_until_big(intcode, x \\ 3, y \\ 4)
  defp scan_until_big(intcode, x, y) do
    {[out1], _intcode} = Intcode.input_and_take_all_outputs(intcode, [x, y])
    {[out2], _intcode} = Intcode.input_and_take_all_outputs(intcode, [x + 1, y])
    if !(out1 == 1 and out2 == 0) do
      scan_until_big(intcode, x + 1, y)
    else
      with true            <- (x - @santa_thicc > 0),
           {[1], _intcode} <- Intcode.input_and_take_all_outputs(intcode,
                                [x - (@santa_thicc - 1), y + (@santa_thicc - 1)]),
           all_coords      <- (for i <- (x - 99)..x, j <- y..(y + 99), do: {i, j}),
           true            <- Enum.all?(all_coords, fn {i, j} ->
                                {[output], _intcode} =
                                  Intcode.input_and_take_all_outputs(intcode, [i, j])
                                output == 1
                              end) do
        {x - 99, y}
      else
        _ -> scan_until_big(intcode, x, y + 1)
      end
    end
  end

  defp scan_area(intcode, x_min..x_max, y_min..y_max) do
    scan_area(intcode, %{}, x_min..x_max, y_min..y_max, x_min, y_min)
  end
  defp scan_area(_intcode, map, _x_range, _y_min..y_max, _x, y) when y > y_max, do: map
  defp scan_area(intcode, map, x_min..x_max = x_range, y_range, x, y) when x > x_max,
    do: scan_area(intcode, map, x_range, y_range, x_min, y + 1)
  defp scan_area(intcode, map, x_range, y_range, x, y) do
    {[output], _intcode} =
      intcode
      |> Intcode.input_and_take_all_outputs([x, y])
    new_map =
      case output do
        1 -> Map.put(map, {x, y}, 1)
        0 -> map
      end
    scan_area(intcode, new_map, x_range, y_range, x + 1, y)
  end
end

input = File.read!("input/19.txt")

Nineteen.one(input)
|> IO.inspect

Nineteen.two(input)
|> IO.inspect
