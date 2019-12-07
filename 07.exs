defmodule Seven do
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

  def permutations([]), do: [[]]
  def permutations(list), do: for elem <- list, rest <- permutations(list -- [elem]), do: [elem|rest]

  def find_max_thrust(intcode) do
    @one_phase_settings
    |> Enum.to_list()
    |> permutations()
    |> Enum.map(&(calculate_thrust(intcode, &1)))
    |> Enum.max()
  end

  def calculate_thrust(intcode, order) do
    Enum.reduce(order, @initial_input, fn x, acc ->
      {_intcode, outputs} = run(intcode, [x, acc])
      List.first(outputs)
    end)
  end

  def find_max_feedback_thrust(intcode) do
    @two_phase_settings
    |> Enum.to_list()
    |> permutations()
    |> Enum.map(&(calculate_feedback_thrust(intcode, &1)))
    |> Enum.max()
  end

  def calculate_feedback_thrust(intcode, order) do
    intcode_states =
      for n <- @two_phase_settings, into: %{}, do: {n,
        %{
          intcode: intcode,
          i: 0,
          inputs: [n]
        }
      }
    first_thruster = List.first(order)
    loop_feedback_thrust(intcode_states, order, first_thruster)
  end

  def loop_feedback_thrust(intcode_states, order, current_thruster, signal \\ 0) do
    state = intcode_states[current_thruster]
    state_with_signal = %{state | inputs: state.inputs ++ [signal]}
    case run_two(state.intcode, state_with_signal.inputs, [], state_with_signal.i) do
      {:halt, {_intcode, _outputs}} ->
        signal
      {:output, {new_intcode, outputs, i}} ->
        new_state = %{
          state |
          intcode: new_intcode,
          i: i,
          inputs: []
        }
        new_states = Map.put(intcode_states, current_thruster, new_state)

        next_thruster =
          if (o = Enum.find_index(order, &(&1 == current_thruster))) == (length(order) - 1) do
            List.first(order)
          else
            Enum.at(order, o + 1)
          end

        [new_signal] = outputs

        loop_feedback_thrust(new_states, order, next_thruster, new_signal)
    end
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

  # ghetto initial quick duct tape solution
  def run_two(intcode, inputs, outputs \\ [], i \\ 0) do
    {opcode, param_modes} = parse_opcode(Enum.at(intcode, i))
    if opcode == 99 do
      {:halt, {intcode, outputs}}
    else
      case opcode do
        1 ->
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          pos = Enum.at(intcode, i + 3)
          sum = a + b
          new_intcode = List.replace_at(intcode, pos, sum)
          run_two(new_intcode, inputs, outputs, i + 4)
        2 ->
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          pos = Enum.at(intcode, i + 3)
          product = a * b
          new_intcode = List.replace_at(intcode, pos, product)
          run_two(new_intcode, inputs, outputs, i + 4)
        3 ->
          total_codes = 2
          {input, new_inputs} = List.pop_at(inputs, 0)
          pos = Enum.at(intcode, i + 1)
          new_intcode = List.replace_at(intcode, pos, input)
          run_two(new_intcode, new_inputs, outputs, i + total_codes)
        4 ->
          total_codes = 2
          output_pos = Enum.at(intcode, i + 1)
          output = Enum.at(intcode, output_pos)
          new_outputs = outputs ++ [output]
          # run(intcode, inputs, new_outputs, i + total_codes)
          {:output, {intcode, new_outputs, i + total_codes}}
        5 ->
          total_codes = 3
          true? = get_value(intcode, param_modes, i, 0) != 0
          new_i = if true?, do: get_value(intcode, param_modes, i, 1), else: i + total_codes
          run_two(intcode, inputs, outputs, new_i)
        6 ->
          total_codes = 3
          false? = get_value(intcode, param_modes, i, 0) == 0
          new_i = if false?, do: get_value(intcode, param_modes, i, 1), else: i + total_codes
          run_two(intcode, inputs, outputs, new_i)
        7 ->
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          result = if (a < b), do: 1, else: 0
          pos = Enum.at(intcode, i + 3)
          new_intcode = List.replace_at(intcode, pos, result)
          run_two(new_intcode, inputs, outputs, i + 4)
        8 ->
          a = get_value(intcode, param_modes, i, 0)
          b = get_value(intcode, param_modes, i, 1)
          result = if (a == b), do: 1, else: 0
          pos = Enum.at(intcode, i + 3)
          new_intcode = List.replace_at(intcode, pos, result)
          run_two(new_intcode, inputs, outputs, i + 4)
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

input = File.read!("input/07.txt")

Seven.one(input)
|> IO.inspect

Seven.two(input)
|> IO.inspect