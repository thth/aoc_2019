defmodule Seventeen do
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

  @input1 'A,B,A,C,B,C,B,A,C,B\n'
  @input2 'L,10,L,6,R,10\n'
  @input3 'R,6,R,8,R,8,L,6,R,8\n'
  @input4 'L,10,R,8,R,8,L,10\n'
  @input5 'n\n'

  def one(input) do
    {outputs, _intcode} =
      input
      |> parse()
      |> Intcode.run_intcode()
      |> Intcode.take_all_outputs()
    {_robot, scaffolds} =
      outputs
      |> parse_ascii()
    scaffolds
    |> Enum.filter(fn scaffold ->
      intersection?(scaffolds, scaffold)
    end)
    |> Enum.map(fn intersection ->
      calculate_alignment(intersection)
    end)
    |> Enum.sum()

  end

  def two(input) do
    intcode = parse(input)
    intcode
    |> Intcode.edit_at_address(0, 2)
    |> run_robot()
    |> elem(0)
    |> List.last()
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Intcode.new()
  end

  defp run_robot(intcode) do
    # hardcoding the solution seemed more fun;
    # pseudocode for real solution:
    # intcode
    # |> run_intcode()
    # |> parse_outputs_for_scaffolds()
    # |> construct_path_through_scaffolds_by_following_line()
    # |> try_movement_chunks_with_two_anchored_to_beginning_and_end()
    # |> run_commands()
    intcode
    |> Intcode.run_intcode()
    |> Intcode.insert_inputs(@input1)
    |> Intcode.run_intcode()
    |> Intcode.insert_inputs(@input2)
    |> Intcode.run_intcode()
    |> Intcode.insert_inputs(@input3)
    |> Intcode.run_intcode()
    |> Intcode.insert_inputs(@input4)
    |> Intcode.run_intcode()
    |> Intcode.insert_inputs(@input5)
    |> Intcode.run_intcode()
    |> Intcode.take_all_outputs()
  end

  defp calculate_alignment({x, y}), do: x * y

  defp intersection?(scaffolds, {x, y}) do
    [{x, y - 1}, {x, y + 1}, {x + 1, y}, {x - 1, y}]
    |> MapSet.new()
    |> MapSet.subset?(scaffolds)
  end

  defp parse_ascii(charlist) do
    parse_ascii(charlist, %{robot: nil, scaffolds: MapSet.new()}, 0, 0)
  end
  defp parse_ascii([], %{robot: robot, scaffolds: scaffolds}, _x, _y),
    do: {robot, scaffolds}
  defp parse_ascii([char | rest], %{scaffolds: scaffolds} = map, x, y) do
    case char do
      ?. -> # space
        parse_ascii(rest, map, x + 1, y)
      ?\n -> # new line
        parse_ascii(rest, map, 0, y + 1)
      ?# -> # scaffold
        new_map = %{map | scaffolds: MapSet.put(scaffolds, {x, y})}
        parse_ascii(rest, new_map, x + 1, y)
      char ->
        new_map = %{map |
          robot: %{
            dir: char, pos: {x, y}},
            scaffolds: MapSet.put(scaffolds, {x, y})
        }
        parse_ascii(rest, new_map, x + 1, y)
    end
  end
end

input = File.read!("input/17.txt")

Seventeen.one(input)
|> IO.inspect

Seventeen.two(input)
|> IO.inspect
