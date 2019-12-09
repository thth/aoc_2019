defmodule Nine do
  defmodule Intcode do
    defstruct intcode: nil, inputs: [], outputs: [], i: 0,
              relative_base: 0, halted?: false

    def run_intcode(state) do
      case step_intcode(state) do
        {:waiting_for_input, new_state} -> new_state
        {:halt, new_state} -> new_state
        {:continue, new_state} ->
          # debug_print(new_state)
          run_intcode(new_state)
      end
    end

    def state_take_output(state) do
      case state.outputs do
        [] -> {nil, state}
        [output | rest] ->
          {
            output,
            %Intcode{state | outputs: rest}
          }
      end
    end

    def state_insert_input(state, input) do
      %Intcode{state | inputs: state.inputs ++ [input]}
    end

    defp step_intcode(%Intcode{
      intcode: intcode,
      inputs: inputs,
      outputs: outputs,
      i: i,
      relative_base: relative_base
      } = state) do

      {opcode, param_modes} = parse_opcode(intcode_at(intcode, i))

      case opcode do
        99 -> # halt
          {:halt, %Intcode{state | halted?: true}}
        1 -> # sum
          a = get_value(intcode, i, relative_base, param_modes, 0)
          b = get_value(intcode, i, relative_base, param_modes, 1)
          pos = get_address(intcode, i, relative_base, param_modes, 2)
          sum = a + b
          new_intcode = intcode_insert(intcode, pos, sum)
          new_i = i + 4
          {:continue, %Intcode{state | intcode: new_intcode, i: new_i}}
        2 -> # product
          a = get_value(intcode, i, relative_base, param_modes, 0)
          b = get_value(intcode, i, relative_base, param_modes, 1)
          pos = get_address(intcode, i, relative_base, param_modes, 2)
          product = a * b
          new_intcode = intcode_insert(intcode, pos, product)
          new_i = i + 4
          {:continue, %Intcode{state | intcode: new_intcode, i: new_i}}
        3 -> # insert input
          case inputs do
            [] ->
              {:waiting_for_input, state}
            [input | rest_inputs] ->
              pos = get_address(intcode, i, relative_base, param_modes, 0)
              new_intcode = intcode_insert(intcode, pos, input)
              total_codes = 2
              new_i = i + total_codes
              {:continue, %Intcode{state | intcode: new_intcode, inputs: rest_inputs, i: new_i}}
          end
        4 -> # enqueue output
          output = get_value(intcode, i, relative_base, param_modes, 0)
          new_outputs = outputs ++ [output]
          total_codes = 2
          new_i = i + total_codes
          {:continue, %Intcode{state | outputs: new_outputs, i: new_i}}
        5 -> # jump-if-true
          true? = true? = get_value(intcode, i, relative_base, param_modes, 0) != 0
          total_codes = 3
          new_i = if true?,
            do: get_value(intcode, i, relative_base, param_modes, 1),
            else: i + total_codes
          {:continue, %Intcode{state | i: new_i}}
        6 -> # jump-if-false
          false? = get_value(intcode, i, relative_base, param_modes, 0) == 0
          total_codes = 3
          new_i = if false?,
            do: get_value(intcode, i, relative_base, param_modes, 1),
            else: i + total_codes
          {:continue, %Intcode{state | i: new_i}}
        7 -> # less than
          a = get_value(intcode, i, relative_base, param_modes, 0)
          b = get_value(intcode, i, relative_base, param_modes, 1)
          result = if (a < b), do: 1, else: 0
          pos = get_address(intcode, i, relative_base, param_modes, 2)
          new_intcode = intcode_insert(intcode, pos, result)
          new_i = i + 4
          {:continue, %Intcode{state | intcode: new_intcode, i: new_i}}
        8 -> # equals
          a = get_value(intcode, i, relative_base, param_modes, 0)
          b = get_value(intcode, i, relative_base, param_modes, 1)
          result = if (a == b), do: 1, else: 0
          pos = get_address(intcode, i, relative_base, param_modes, 2)
          new_intcode = intcode_insert(intcode, pos, result)
          new_i = i + 4
          {:continue, %Intcode{state | intcode: new_intcode, i: new_i}}
        9 -> # adjust relative base
          a = get_value(intcode, i, relative_base, param_modes, 0)
          new_relative_base = relative_base + a
          new_i = i + 2
          {:continue, %Intcode{state | relative_base: new_relative_base, i: new_i}}
      end
    end

    defp get_value(intcode, i, relative_base, param_modes, param_number) do
      param_mode = Enum.at(param_modes, param_number, 0)
      param = intcode_at(intcode, i + param_number + 1)

      case param_mode do
        2 -> # relative
          intcode_at(intcode, relative_base + param)
        1 -> # immediate
          param
        0 -> # position
          intcode_at(intcode, param)
      end
    end

    defp get_address(intcode, i, relative_base, param_modes, param_number) do
      param_mode = Enum.at(param_modes, param_number, 0)
      param = intcode_at(intcode, i + param_number + 1)

      case param_mode do
        0 -> # position
          param
        2 -> # relative
          param + relative_base
      end
    end

    defp parse_opcode(n) do
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

    defp intcode_at(intcode, i) do
      Enum.at(intcode, i, 0)
    end

    defp intcode_insert(intcode, i, value) when i < length(intcode),
      do: List.replace_at(intcode, i, value)
    defp intcode_insert(intcode, i, value) do
      filler_positions = i - length(intcode)
      intcode ++ List.duplicate(0, filler_positions) ++ [value]
    end

    def debug_print(%Intcode{intcode: intcode, i: i, relative_base: relative_base}) do
      File.mkdir_p!(Path.dirname("debug"))
      output =
        intcode
        |> Enum.map(&Integer.to_string/1)
        |> Enum.with_index()
        |> Enum.reduce("", fn {x, current_i}, acc ->
          li = String.pad_leading(current_i |> Integer.to_string(), 4, "0")
          if current_i == i do
            acc <> "\n#{li}: #{x} <"
          else
            acc <> "\n#{li}: #{x}"
          end
        end)
      path = "debug/#{:os.system_time()}.txt"
      File.write(path, "#{Integer.to_string(relative_base)}")
      File.write(path, output, [:append])
    end
  end

  @one_input 1
  @two_input 2

  def one(input) do
    input
    |> parse()
    |> Intcode.state_insert_input(@one_input)
    |> Intcode.run_intcode()
    |> Intcode.state_take_output()
    |> elem(0)
  end

  def two(input) do
    input
    |> parse()
    |> Intcode.state_insert_input(@two_input)
    |> Intcode.run_intcode()
    |> Intcode.state_take_output()
    |> elem(0)
  end

  def parse(raw) do
    list =
      raw
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)
    %Intcode{intcode: list}
  end
end

input = File.read!("input/09.txt")

Nine.one(input)
|> IO.inspect

Nine.two(input)
|> IO.inspect
