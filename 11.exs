defmodule Eleven do
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

    def insert_inputs(state, inputs) do
      %Intcode{state | inputs: state.inputs ++ inputs}
    end

    def take_outputs(state, number \\ 1) do
      {results, rest} = Enum.split(state.outputs, number)
      {results, %Intcode{state | outputs: rest}}
    end

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

  def one(input) do
    input
    |> parse()
    |> loop_until_halt()
    |> count_tiles()
  end

  def two(input) do
    input
    |> parse()
    |> loop_until_halt(%{{0, 0} => [1]})
    |> draw()
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Intcode.new()
  end

  defp loop_until_halt(state, paint_map \\ %{}, pos \\ {0, 0}, dir \\ :up)
  defp loop_until_halt(%Intcode{halted?: true}, paint_map, _pos, _dir), do: paint_map
  defp loop_until_halt(state, paint_map, pos, dir) do
    current_tile = get_current_tile(paint_map, pos)
    {[color, turn], new_state} =
      state
      |> Intcode.insert_inputs([current_tile])
      |> Intcode.run_intcode()
      |> Intcode.take_outputs(2)
    new_paint_map = update_paint_map(paint_map, pos, color)
    {new_pos, new_dir} = update_pos_and_dir(pos, dir, turn)

    loop_until_halt(new_state, new_paint_map, new_pos, new_dir)
  end

  defp get_current_tile(paint_map, pos) do
    case Map.get(paint_map, pos) do
      nil -> 0
      [color | _rest] -> color
    end
  end

  defp update_paint_map(paint_map, pos, color) do
    case Map.get(paint_map, pos) do
      nil -> Map.put(paint_map, pos, [color])
      list -> Map.put(paint_map, pos, [color | list])
    end
  end

  defp update_pos_and_dir({x, y}, dir, turn) do
    case turn do
      0 -> # left
        case dir do
          :up -> {{x - 1, y}, :left}
          :down -> {{x + 1, y}, :right}
          :left -> {{x, y + 1}, :down}
          :right -> {{x, y - 1}, :up}
        end
      1 -> # right
        case dir do
          :up -> {{x + 1, y}, :right}
          :down -> {{x - 1, y}, :left}
          :left -> {{x, y - 1}, :up}
          :right -> {{x, y + 1}, :down}
        end
    end
  end

  defp count_tiles(paint_map) do
    Map.keys(paint_map) |> length()
  end
  
  def draw(paint_map) do
    coords = Map.keys(paint_map)
    x_min = coords |> Enum.min_by(&(elem(&1, 0))) |> elem(0)
    x_max = coords |> Enum.max_by(&(elem(&1, 0))) |> elem(0)
    y_min = coords |> Enum.min_by(&(elem(&1, 1))) |> elem(1)
    y_max = coords |> Enum.max_by(&(elem(&1, 1))) |> elem(1)

    y_min..y_max
    |> Enum.each(fn y ->
      x_min..x_max
      |> Enum.map(fn x ->
        case Map.get(paint_map, {x, y}, [0]) do
          [0 | _] -> " "
          [1 | _] -> "#"
        end
      end)
      |> Enum.reduce(fn x, acc ->  acc <> x end)
      |> IO.puts
    end)
  end
end

input = File.read!("input/11.txt")

Eleven.one(input)
|> IO.inspect

Eleven.two(input)
