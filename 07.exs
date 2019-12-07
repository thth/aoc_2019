defmodule Seven do
  defmodule Intcode do
    defstruct intcode: nil, inputs: [], outputs: [], i: 0, halted?: false

    def run_intcode(state) do
      case step_intcode(state) do
        {:waiting_for_input, new_state} -> new_state
        {:halt, new_state} -> new_state
        {:continue, new_state} -> run_intcode(new_state)
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
      i: i
      } = state) do

      {opcode, param_modes} = parse_opcode(Enum.at(intcode, i))

      case opcode do
        99 -> # halt
          {:halt, %Intcode{state | halted?: true}}
        1 -> # sum
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          pos = Enum.at(intcode, i + 3)
          sum = a + b
          new_intcode = List.replace_at(intcode, pos, sum)
          new_i = i + 4
          {:continue, %Intcode{state | intcode: new_intcode, i: new_i}}
        2 -> # product
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          pos = Enum.at(intcode, i + 3)
          product = a * b
          new_intcode = List.replace_at(intcode, pos, product)
          new_i = i + 4
          {:continue, %Intcode{state | intcode: new_intcode, i: new_i}}
        3 -> # insert input
          case inputs do
            [] ->
              {:waiting_for_input, state}
            [input | rest_inputs] ->
              pos = Enum.at(intcode, i + 1)
              new_intcode = List.replace_at(intcode, pos, input)
              total_codes = 2
              new_i = i + total_codes
              {:continue, %Intcode{state | intcode: new_intcode, inputs: rest_inputs, i: new_i}}
          end
        4 -> # enqueue output
          output_pos = Enum.at(intcode, i + 1)
          output = Enum.at(intcode, output_pos)
          new_outputs = outputs ++ [output]
          total_codes = 2
          new_i = i + total_codes
          {:continue, %Intcode{state | outputs: new_outputs, i: new_i}}
        5 -> # jump-if-true
          true? = true? = get_value(intcode, param_modes, i, 0) != 0
          total_codes = 3
          new_i = if true?, do: get_value(intcode, param_modes, i, 1), else: i + total_codes
          {:continue, %Intcode{state | i: new_i}}
        6 -> # jump-if-false
          false? = get_value(intcode, param_modes, i, 0) == 0
          total_codes = 3
          new_i = if false?, do: get_value(intcode, param_modes, i, 1), else: i + total_codes
          {:continue, %Intcode{state | i: new_i}}
        7 -> # less than
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          result = if (a < b), do: 1, else: 0
          pos = Enum.at(intcode, i + 3)
          new_intcode = List.replace_at(intcode, pos, result)
          new_i = i + 4
          {:continue, %Intcode{state | intcode: new_intcode, i: new_i}}
        8 -> # equals
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          result = if (a == b), do: 1, else: 0
          pos = Enum.at(intcode, i + 3)
          new_intcode = List.replace_at(intcode, pos, result)
          new_i = i + 4
          {:continue, %Intcode{state | intcode: new_intcode, i: new_i}}
      end
    end

    defp get_value(intcode, param_modes, i, param_number) do
      param_mode = Enum.at(param_modes, param_number, 0)
      case param_mode do
        1 -> # immediate
          Enum.at(intcode, i + param_number + 1)
        0 -> # position
          Enum.at(intcode, 225)
          Enum.at(intcode, Enum.at(intcode, i + param_number + 1))
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
  end

  @initial_input 0
  @one_phase_settings 0..4
  @two_phase_settings 5..9

  def one(input) do
    input
    |> parse()
    |> find_max_thrust()
  end

  def two(input) do
    input
    |> parse()
    |> find_max_feedback_thrust()
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Enum.map(&String.to_integer/1)
  end

  # miiight be copypasted
  def permutations([]), do: [[]]
  def permutations(list),
    do: for elem <- list, rest <- permutations(list -- [elem]), do: [elem | rest]

  def find_max_thrust(intcode) do
    @one_phase_settings
    |> Enum.to_list()
    |> permutations()
    |> Enum.map(&(calculate_thrust(intcode, &1)))
    |> Enum.max()
  end

  def calculate_thrust(intcode, order) do
    initial_states =
      order
      |> Enum.into(%{}, fn n ->
        {n, %Intcode{intcode: intcode, inputs: [n]}}
      end)

    Enum.reduce(order, {initial_states, @initial_input}, fn n, {states, signal} ->
      {output, new_state} =
        states[n]
        |> Intcode.state_insert_input(signal)
        |> Intcode.run_intcode()
        |> Intcode.state_take_output()
      {Map.put(states, n, new_state), output}
    end)
    |> elem(1)
  end

  def find_max_feedback_thrust(intcode) do
    @two_phase_settings
    |> Enum.to_list()
    |> permutations()
    |> Enum.map(&(calculate_feedback_thrust(intcode, &1)))
    |> Enum.max()
  end

  def calculate_feedback_thrust(intcode, order) do
    initial_states =
      order
      |> Enum.into(%{}, fn n ->
        {n, %Intcode{intcode: intcode, inputs: [n]}}
      end)
    first_thruster = List.first(order)
    loop_feedback_thrust(initial_states, order, first_thruster)
  end

  def loop_feedback_thrust(states, order, current, signal \\ 0) do
    %Intcode{halted?: halted?} = states[current]
    if halted? do
      signal
    else
      {output, new_state} =
        states[current]
        |> Intcode.state_insert_input(signal)
        |> Intcode.run_intcode()
        |> Intcode.state_take_output()
      new_states = Map.put(states, current, new_state)
      next_thruster = find_next_thruster(order, current)
      loop_feedback_thrust(new_states, order, next_thruster, output)
    end
  end

  def find_next_thruster(order, current_thruster) do
    i = Enum.find_index(order, &(&1 == current_thruster))
    Stream.cycle(order)
    |> Enum.at(i + 1)
  end
end

input = File.read!("input/07.txt")

Seven.one(input)
|> IO.inspect

Seven.two(input)
|> IO.inspect