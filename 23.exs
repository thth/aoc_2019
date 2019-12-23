defmodule TwentyThree do
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

  def one_two(input) do
    intcode =
      input
      |> parse()
    address_book =
      0..49
      |> Enum.reduce(%{}, fn n, acc ->
        pid = spawn(fn -> init(intcode, n) end)
        Map.put(acc, n, pid)
      end)
    Enum.each(address_book, fn {_address, pid} ->
      send(pid, Map.put(address_book, 255, self()))
    end)

    nat(address_book[0])
  end

  def parse(raw) do
    raw
    |> String.split(",")
    |> Intcode.new()
  end

  defp nat(address_0) do
    idle_map = for n <- 0..49, into: %{}, do: {n, false}
    nat(idle_map, address_0, nil, nil)
  end

  defp nat(idle_map, address_0, current_packet, last_sent) do 
    receive do
      {from, :idle} ->
        new_idle_map = Map.put(idle_map, from, true)
        if Enum.all?(idle_map, fn {_address, idle?} -> idle? end) do
          if current_packet == last_sent do
            IO.puts("nat sent #{inspect(current_packet)} twice in a row; " <>
              "second answer is #{elem(current_packet, 1)}")
          else
            # IO.puts("nat sending #{inspect(current_packet)}")
            send(address_0, {255, current_packet})
            new_idle_map = for n <- 0..49, into: %{}, do: {n, false}
            nat(new_idle_map, address_0, current_packet, current_packet)
          end
        else
          nat(new_idle_map, address_0, current_packet, last_sent)
        end
      {from, :active} ->
        new_idle_map = Map.put(idle_map, from, false)
        nat(new_idle_map, address_0, current_packet, last_sent)
      {from, packet} ->
        if current_packet == nil do
          IO.puts("received first packet: #{inspect(packet)}; "
            <> "first answer is #{elem(packet, 1)}")
        end
        new_idle_map = Map.put(idle_map, from, false)
        nat(new_idle_map, address_0, packet, last_sent)
    end
  end

  defp init(intcode, address) do
    receive do
      %{} = address_book ->
        intcode
        |> Intcode.insert_inputs([address])
        |> run(address_book, address)
    end
  end

  defp run(intcode, address_book, address) do
    {outputs, intcode} =
      intcode
      |> Intcode.run_intcode()
      |> Intcode.take_all_outputs()
    
    :ok = send_outputs(address_book, address, outputs)

    if intcode.halted? do
      IO.puts("halting #{address}")
    else
      receive do
        {_from, {x, y}} ->
          notify_nat(address_book, address, :active)
          new_intcode = Intcode.insert_inputs(intcode, [x, y])
          run(new_intcode, address_book, address)
        err -> raise err
      after
        3 ->
          notify_nat(address_book, address, :idle)
          new_intcode = Intcode.insert_inputs(intcode, [-1])
          run(new_intcode, address_book, address)
      end
    end
  end

  defp send_outputs(_address_book, _self_address, []), do: :ok
  defp send_outputs(address_book, self_address, [address | [x | [y | rest]]]) do
    send(address_book[address], {self_address, {x, y}})
    send_outputs(address_book, self_address, rest)
  end

  defp notify_nat(%{255 => nat_address}, address, msg) do
    send(nat_address, {address, msg})
  end
end

input = File.read!("input/23.txt")

TwentyThree.one_two(input)
