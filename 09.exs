defmodule Nine do
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

    def insert_input(state, input) do
      %Intcode{state | inputs: state.inputs ++ [input]}
    end

    def take_output(%Intcode{outputs: []} = state), do: {nil, state}
    def take_output(%Intcode{outputs: [output | rest]} = state), do:
      {output, %Intcode{state | outputs: rest}}

    def run_intcode(state) do
      case step_intcode(state) do
        {:waiting_for_input, new_state} -> new_state
        {:halt, new_state} -> new_state
        {:continue, new_state} -> run_intcode(new_state)
      end
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

  @one_input 1
  @two_input 2

  def one(input) do
    input
    |> parse()
    |> Intcode.insert_input(@one_input)
    |> Intcode.run_intcode()
    |> Intcode.take_output()
    |> elem(0)
  end

  def two(input) do
    input
    |> parse()
    |> Intcode.insert_input(@two_input)
    |> Intcode.run_intcode()
    |> Intcode.take_output()
    |> elem(0)
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Intcode.new()
  end
end

input = File.read!("input/09.txt")

Nine.one(input)
|> IO.inspect

Nine.two(input)
|> IO.inspect