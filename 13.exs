defmodule Thirteen do
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

    def init_inputs(state, inputs) do
      %Intcode{state | inputs: inputs}
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
        # 4 -> # enqueue output
        #   output = get_value(intcode, pointer, relative_base, ins_modes, 1)
        #   {:continue, %Intcode{state |
        #     outputs: [output | outputs],
        #     pointer: pointer + 2
        #   }}
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

  defmodule Game do
    defstruct tiles: %{}, score: nil, i: 0, x_range: nil, y_range: nil, prev_ball: nil
  end
  @block_id 2
  @tiles %{
    0 => " ", # empty
    1 => "#", # wall
    2 => "x", # block
    3 => "@", # paddle
    4 => "O", # ball
    5 => "."
  }

  def one(input) do
    input
    |> parse()
    |> Intcode.run_intcode()
    |> construct_game_state()
    |> Map.get(:tiles)
    |> Enum.count(fn {_pos, id} -> id == @block_id end)
  end

  def two(input, game_inputs) do
    parsed_game_inputs =
      game_inputs
      |> String.replace("\n", "")
      |> String.graphemes()
      |> Enum.map(&parse_input/1)
    {_intcode, game_state} =
      input
      |> parse()
      |> Intcode.edit_at_address(0, 2)
      |> input_loop(parsed_game_inputs)
    draw(game_state)
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Intcode.new()
  end

  defp input_loop(intcode, game_inputs) do
    new_intcode = Intcode.run_intcode(intcode)
    game_state = construct_game_state(new_intcode)
    {{x_min, x_max}, {y_min, y_max}} = find_coord_range(game_state)
    current_ball_pos = find_ball_pos(game_state)
    game_state_with_coords =
      %Game{
        game_state |
        x_range: x_min..x_max,
        y_range: y_min..y_max,
        prev_ball: current_ball_pos,
      }

    game_loop(new_intcode, game_state_with_coords, game_inputs)
  end

  defp game_loop(intcode, game_state, []), do: {intcode, game_state}
  defp game_loop(intcode, game_state, [input | rest]) do
    {new_intcode, new_game_state} =
      intcode
      |> Intcode.init_inputs([input])
      |> Intcode.run_intcode()
      |> process_game_state(game_state)
    game_loop(new_intcode, new_game_state, rest)
  end

  defp process_game_state(intcode, %Game{i: i} = game_state) do
    current_ball_pos = find_ball_pos(game_state)
    new_game_state = %Game{
      construct_game_state(intcode, game_state) |
      prev_ball: current_ball_pos,
      i: i + 1,
    }

    clean_intcode = %Intcode{intcode | outputs: []} 
    {clean_intcode, new_game_state}
  end

  defp find_ball_pos(%Game{tiles: tiles}) do
    {{x, y}, 4} = Enum.find(tiles, fn {{_x, _y}, id} -> id == 4 end)
    {x, y}
  end

  defp find_coord_range(game_state) do
    coords = Map.keys(game_state.tiles)
    x_min = coords |> Enum.min_by(&(elem(&1, 0))) |> elem(0)
    x_max = coords |> Enum.max_by(&(elem(&1, 0))) |> elem(0)
    y_min = coords |> Enum.min_by(&(elem(&1, 1))) |> elem(1)
    y_max = coords |> Enum.max_by(&(elem(&1, 1))) |> elem(1)
    {{x_min, x_max}, {y_min, y_max}}
  end

  defp parse_input(input) do
    case input do
      "z" -> -1
      "x" -> 0
      "c" -> 1
    end
  end

  defp construct_game_state(intcode, game_state \\ %Game{})
  defp construct_game_state(%Intcode{outputs: []}, game_state), do: game_state
  defp construct_game_state(intcode, %Game{tiles: tiles} = game_state) do
    {[x, y, id], new_intcode} = Intcode.take_outputs(intcode, 3)
    new_game_state =
      case {x, y, id} do
        {-1, 0, id} ->
          %Game{game_state | score: id}
        {x, y, 0} ->
          %Game{game_state | tiles: Map.delete(tiles, {x, y})}
        {x, y, id} ->
          %Game{game_state | tiles: Map.put(tiles, {x,  y}, id)}
      end
    construct_game_state(new_intcode, new_game_state)
  end

  defp draw(%Game{prev_ball: prev_ball_pos} = game_state) do
    tiles = if prev_ball_pos, do: Map.put(game_state.tiles, prev_ball_pos, 5), else: game_state.tiles
    left = Enum.filter(game_state.tiles, fn {_pos, id} -> id == 2 end) |> length()
    IO.puts("i: #{game_state.i}, score: #{game_state.score}, left: #{left}")
    game_state.y_range
    |> Enum.each(fn y ->
      game_state.x_range
      |> Enum.map(fn x ->
        tile_id = Map.get(tiles, {x, y}, 0)
        Map.get(@tiles, tile_id)
      end)
      |> Enum.join("")
      |> IO.puts
    end)
  end
end

input = File.read!("input/13.txt")

Thirteen.one(input)
|> IO.inspect

game_inputs = """
xxxxxxzzccccxzzzxcccczzzzcccccxxzzzccccxxxxxzxxzzzxcccxcxxxxzxxxzzzzzcccxxxccczzczzxxzzzxcccxxcccccz
zzzzxxzzzxccxcxxxxxxxxxxxxxxxxxxxcccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzcccxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxccczzzzzxcccccczzzxxxxxxxxcccczzzzzzxxxxccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzxxxxxxxxxxxx
cccccccccccccczzzzxxzzzzzxxxxxxxxxxxxxxxxxxxxxxxxxzxxxxxxxxzzxzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxccccccx
xxxxxxxxxxxxxxxxcczzzzzzxxxxxxcccccccczzzzzzxxxxxxxzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzxxx
xxxxxxxxxxccczzzzxxxzxxxxxxxxxxxxxxxxzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcxzcccxxcccccccccccxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxccccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzxxxxxxxcxxxxxxxxxxxxccccccccccccccccccccccccx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxcccccc
cccccccxcccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxxxx
cccccccxxxxxxxxxxxxxxxxxxxxxxxxxxzzzxzzzzzzccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxccccccccccxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxccccccccccxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxccccxxxxxxxxzxxxxxxxxxxxxccccccccczzzxxxxxxxxxxxzxxxzxxxxxxxxxxxxxxccczxxzzxxxxx
xxxxxxxxxxxxxxxxxzzzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxccc
xxxccccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzccccccccccccccccccccccccccccczzzzzzzxxxxxzzzzxxxxx
xxxxxxxxxxxxxxzxcccccccccccxxxxxxxxxxzzzzzzzzzzzzzzzzzcccccccccccccccccczxxxxxxxxxxxxzzzzzzzzzxxzzzz
xxxxxxxccccccccccccccczzxxxxxxxxxxzzzzzzzzzzzzzzzzzzzxxxxxxxxccccccccccccccccccxccczzzzzxxzzzzzzzzzz
zzzzzzzzzzzzzzzzzzzxxxxxxcccccccccccccccccccccccccccccccccxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxzzzzzzcccc
xxxcccccccccccxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzccccccccccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xzzzzzzzzzzzzzxxxxxxxxxxxxxccccccccccccccccccccccccccccxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzxxxxxx
xxxxxxxccccccccccccccccxxxxxxxcxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzxzzzzzzzzzzzcccccxxxxxxxxxxcccccccccccc
xxxxcccxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxccccccccccccccccxxxxxxxxxxxxxxxxxxxx
xxzzzzzzzzxxzzzzzzzzxxxxxxxxxxxxxxxxxxxxccccccccccccxxxccccxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzxxxxxxx
xxxxxxxxxxxxxxxxxcccxzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcccccccxxxxxxxx
xxxxxxxxxxxxxxxxxzzzzzzzzxccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxzxxxxxxxxxxxxxxxxxxxxcccccccccccccxxxxccxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzxxxxxxxxxxx
xxxxxxxxcccccccccccccccccxzzzzzxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzzxxxxcccccccccccccccccccccc
cccxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzcccccccccccccccccccccxxxxxxxxxxxxzzzxxxxxxxxxxxxxxxxxxx
zzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxcccccccccccccccccxxxxzzzzzzzzzxxxxxxxxxxxxxxxxxxxzxzzzzzzxxzzzzzzzz
xxcccccccccccccccccccccccccxxzzzzzzxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxxxccccccccccc
cccccxcxxxxxxxxxcccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzz
zxxxcxxxxxxxxxxxxxxxxxxxxxxxxxxcccccxxxccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzz
xxxxxxccccccccccccccccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcxxxxxxzzzzzzzzzzzzzzzzzxxxxzzxzzzcxxxxxxxx
xxxxxxxxxxxxxxzzxxxxxxxxxxxxxxxxxxxxxxxxxxccxxxxxxxxxxxxxxccccccccccccccccccccccccxxxxxxxxxxxxxxxxxx
zzzzzzzzzzzzzzzxxxxzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxccccccccccccccccc
xxxxxxxzxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxxxccccccccccccccczzzzczzzzzzzzzzz
zxxxxxxxxxxxxxxxccccccccccccccccccxxcccccccccccxxxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzcxxxxxxxxxxxxxxcccccccccccccccccccccccccccxxxxxxxxxxzzzzzzz
zzzzzzzzzzzzzzzzzzzzxxxxxxxxxcccccccccccccccccccccccccxxzzzzzzzzzzzzzzzzzzzzxxxxxxxxxxxxxcccxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcccccccccccccxxxcxxxccxxzzzzzzzzzzzzzz
xxxxxxxxxxzzzzzzzzzzzccxxxxxxxxxxxcccccccccccccccccccxxxccccccxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzzzzzzx
xxxxxxxxxxxxxccccccccccccccccccccccccccxxxxxzzzzzzzzzzzzzzzzzzzzzzzzxxxzzzxxxxxxxccccccxcccccccccccc
ccccccccccccccxxxxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxxxxxxcxccccccccccccccccccccccccxcxccczzzzzzzz
zzzzzzzzzzzzzzzzzxxxccccccxcccccccccccccccccccczzczzzzzzzzzzzzxcccxxxxxxxxxxxxxxxxxxxxxzzxxzxzxxxxzz
zzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxccccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzxxxzzzzxxxxxxxxxxxxxxxxxxxxx
xccccccccccccccccxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzzzzzxxxxxxcccccccccccccccccccccccccccccccczzzzzzzz
xzzzxxzzzzxzzzzzzzzzzzzzzzzczzzzzcccccccccccccccccccccccccccccccccccxxxxxxxxxxzzzxzzzzxzzzzzzzzzzzzz
zzzzzzzzzzzzxxxxxxxxxxxxxccccccccccccccccccccccccxczxxxxxxzzzzzzzzzzzzzzzzzzzzzzzzccccccccxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxccccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzxxzxxxxxxxxxxxxxxxxx
cccccccxxxxxcxccccccccxxxxxxxxxzzxxzzzzzzzzzzzzzzzzzzzzzzxxxxxxxxxccccccccccccccccccccccccccccccccxx
xxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxxxxxxxxcccccccccccccccccccccccxxxcxxxxxxxxx
zzzzzzzzzzzzzzzxxxxxzxzxzxxxxxccxxxxxxxxxxxxxxxxxxxcccccccccccxxxxxzxzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzxzxxxxxxxxxxxxxxxxcccxxxxcccccccccccccczxxxxxxxxxzxxxxxx
zzzzzzzzzzzzzzzzzzzzzzzxxxxcccccccccccccccccccccccccccccxcccxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzxx
cccccccccccxxxxzxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxxxxxxxxxxxxxxxcccccccccccccccccccccccccxzxxxxxxxx
zzzzzzzzzzzzzzzzzzxxxxxxxxxxxccxxxxxxxxxxxxxxccccccccccccczzzccxzzzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzxxxxxxxxxxxxxxxcccccccxxcccccccccccczzzxxxxxxxxxzzzzzzzzz
xxxzzzzzzzzzzzzxxxzzzxxxxxxccccccccccccccccccccccccccccccccxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzxxx
xxxxxxxxxxxcccccccccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxczzzzzzzzzzzzzzzzzzzzzzzzzzz
zzzzzzzzzzxcccccccccccccccccccccccccccccccccccccczzzzzzzxzzzzzzzzzzzzzzzzzzzzzzzxxxxzzxxxxxxxxxxxxxx
ccccccccccccccccccccccccxzzzzzzzzzzzzzxxxxxxxxxxxxzzxxxxxxzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxccccccccxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxzxxxxxxxxxxxcxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzxxxxxccxxxxxxxxxxxxxxxccccccccc
cccccccccczzzxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzccccxxxcxccccccccccccccccccccccccccccccccccxzzxzzzzzzzzz
zzzzzzzzzzzzzzzzzzzzzzzzzzzzzcccccccccccccccccccccccccccccccccccxcxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxccccccccccccccccccccccccccccc
ccccccccczzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxxxxxccccccccccccccccccccccxxxxxxxxxxxxxccxzzzzzzzzzzzzzzz
xxxxxxxxxxxxxxxxxxxzzcxxxxxxxxxxxxxxxxxxxccccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
zzzzxxxxxxxxxxxxxxxxxxxxxxxxxxzzxzzxxxxxxxxxxxxxxxxxxxxxxxccccccccccccccccxxxxxxzzzzzzzzzzzzzzzzzzzz
xxxzzzxxxxxzxcccccccccccccccccccccccccccccccccczzxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzccccccccccc
cccccccccccccccccccccccccxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxcxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxccccccccccccccccxccxcccccczzzzzzzzzzzzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ccccccxxxxxxxxxxxxxxxxzzzzzzzzzzzzxxxxxxxxxxxxxcxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ccccccccccczzzzzzzzzzxxxxcccccccxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzzxxxxxxxxxxxxxxxxxxxxxxxzzzzxxzzzzz
zzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxzxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxcccccccccccccccccccccxxxxxxxxxxxxxxcxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz
xxxxxxcxxccccccccccccccccccccccccccccccccccccxxzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzccccccccccccccc
cccccccccccccccccxxxxxxzzzzzzzzzzzzzzzzzzzzxxxxxxxxxxxxx
"""

Thirteen.two(input, game_inputs)