defmodule Fifteen do
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

  def one(input) do
    {dir_map, oxygen_location} =
      input
      |> parse()
      |> construct_map()
    tiles = Map.keys(dir_map) |> MapSet.new()
    find_shortest_distance(tiles, oxygen_location)
  end

  def two(input) do
    {dir_map, oxygen_location} =
      input
      |> parse()
      |> construct_map()
    tiles = Map.keys(dir_map) |> MapSet.new()
    find_minutes_to_full(tiles, oxygen_location)
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Intcode.new()
  end

  defp find_minutes_to_full(tiles, origin) do
    next_tiles = MapSet.new([origin])
    find_minutes_to_full(tiles, MapSet.new(), next_tiles)
  end

  defp find_minutes_to_full(tiles, past_tiles, current_tiles, minutes \\ 0) do
    next_tiles =
      current_tiles
      |> Enum.map(&surrounding_tiles/1)
      |> List.flatten()
      |> Enum.filter(fn tile -> MapSet.member?(tiles, tile) end)
      |> MapSet.new()
      |> MapSet.difference(past_tiles)
    if MapSet.size(next_tiles) == 0 do
      minutes
    else
      new_past_tiles = MapSet.union(past_tiles, current_tiles)
      find_minutes_to_full(tiles, new_past_tiles, next_tiles, minutes + 1)
    end
  end

  defp find_shortest_distance(_, {0, 0}), do: 0
  defp find_shortest_distance(tiles, destination) do
    next_tiles = MapSet.new([{0, 0}])
    find_shortest_distance(tiles, MapSet.new(), next_tiles, destination, 0)
  end

  defp find_shortest_distance(tiles, past_tiles, current_tiles, destination, distance) do
    next_tiles =
      current_tiles
      |> Enum.map(&surrounding_tiles/1)
      |> List.flatten()
      |> Enum.filter(fn tile -> MapSet.member?(tiles, tile) end)
      |> MapSet.new()
      |> MapSet.difference(past_tiles)
    if MapSet.member?(next_tiles, destination) do
      distance + 1
    else
      new_past_tiles = MapSet.union(past_tiles, current_tiles)
      find_shortest_distance(tiles, new_past_tiles, next_tiles, destination, distance + 1)
    end
  end

  defp construct_map(intcode) do
    tiles_to_check = [
      {{0, 0}, {0, 1}, 1},
      {{0, 0}, {0, -1}, 2},
      {{0, 0}, {-1, 0}, 3},
      {{0, 0}, {1, 0}, 4}
    ]
    base_map = %{
      {0, 0} => []
    }
    construct_map(intcode, base_map, tiles_to_check, MapSet.new(), nil)
  end

  defp construct_map(_intcode, dir_map, [], _checked_tiles, oxygen_location), do: {dir_map, oxygen_location}
  defp construct_map(intcode, dir_map, [{pos_from, pos_to_check, dir}| rest], checked_tiles, oxygen_location) do
    inputs = Map.get(dir_map, pos_from) ++ [dir]
    {outputs, _intcode} = Intcode.input_and_take_all_outputs(intcode, inputs)
    output = List.last(outputs)
    new_checked_tiles = MapSet.put(checked_tiles, pos_to_check)
    case output do
      0 -> # wall
        construct_map(intcode, dir_map, rest, new_checked_tiles, oxygen_location)
      _ ->
        new_dir_map = Map.put(dir_map, pos_to_check, inputs)
        unchecked_surrounding_tiles =
          pos_to_check
          |> queue_format_surrounding_tiles()
          |> Enum.filter(fn {_, tile, _} -> !MapSet.member?(new_checked_tiles, tile) end)
        new_tiles_to_check = unchecked_surrounding_tiles ++ rest
        case output do
          1 -> construct_map(intcode, new_dir_map, new_tiles_to_check, new_checked_tiles, oxygen_location)
          2 -> construct_map(intcode, new_dir_map, new_tiles_to_check, new_checked_tiles, pos_to_check)
        end
    end
  end

  defp queue_format_surrounding_tiles({x, y} = pos) do
    [
      {pos, {x, y + 1}, 1},
      {pos, {x, y - 1}, 2},
      {pos, {x - 1, y}, 3},
      {pos, {x + 1, y}, 4}
    ]
  end

  defp surrounding_tiles({x, y}) do
    [
      {x, y + 1},
      {x, y - 1},
      {x - 1, y},
      {x + 1, y}
    ]
  end


end

input = File.read!("input/15.txt")

Fifteen.one(input)
|> IO.inspect

Fifteen.two(input)
|> IO.inspect
