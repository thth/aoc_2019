defmodule Sixteen do

  defmodule Big do
    defstruct [:digit_list, :offset, :number_length]

    def new(digit_list, repetitions \\ 1, offset \\ 0) do
      number_length = length(digit_list) * repetitions
      trimmed_digit_list =
        digit_list
        |> Stream.cycle()
        |> Enum.slice(offset, number_length - offset)
      %__MODULE__{
        digit_list: trimmed_digit_list,
        offset: offset,
        number_length: number_length
      }
    end

    def get_offset(digit_list, offset_length) do
      digit_list
      |> Enum.take(offset_length)
      |> Integer.undigits()
    end

    def get_first_digits(%Big{digit_list: digit_list}, number_of_digits) do
      digit_list
      |> Enum.take(number_of_digits)
      |> Enum.join()
    end
  end
  @base_pattern [0, 1, 0, -1]
  @number_of_phases 100
  @first_number_of_digits 8
  @signal_repetitions 10_000
  @offset_length 7

  def one(input) do
    input
    |> parse()
    |> Big.new()
    |> transform_times(@number_of_phases)
    |> Big.get_first_digits(@first_number_of_digits)
  end

  def two(input) do
    offset = Big.get_offset(parse(input), @offset_length)

    input
    |> parse()
    |> Big.new(@signal_repetitions, offset)
    |> cheat(@number_of_phases)
  end

  def parse(raw) do
    raw
    |> String.to_integer()
    |> Integer.digits()
  end

  defp cheat(%Big{digit_list: digit_list}, times) do
    reversed_digits = Enum.reverse(digit_list)
    cheat(reversed_digits, times, 0)
  end
  defp cheat(reversed_list, times, iteration) when times == iteration do
    reversed_list
    |> Enum.reverse()
    |> Enum.take(@first_number_of_digits)
    |> Enum.map(&(rem(&1, 10)))
    |> Enum.map(&Integer.to_string/1)
    |> Enum.join()
  end
  defp cheat(reversed_list, times, iteration) do
    new_reversed_list =
      Enum.reduce(reversed_list, {0, []}, fn x, {running_sum, acc} ->
        new_sum = x + running_sum
        {new_sum, [new_sum | acc]}
      end)
      |> elem(1)
      |> Enum.reverse()
    cheat(new_reversed_list, times, iteration + 1)
  end

  defp transform_times(big, times, iteration \\ 0)
  defp transform_times(big, times, iteration) when times == iteration, do: big
  defp transform_times(%Big{
    digit_list: digit_list,
    offset: offset,
    number_length: number_length,
    } = big, times, iteration) do

    new_digit_list =
      offset..(number_length - 1)
      |> Enum.map(&(create_digit(digit_list, &1, offset)))
    new_big = %Big{big | digit_list: new_digit_list}
    transform_times(new_big, times, iteration + 1)
  end

  defp create_digit(digit_list, number_index, offset) do
    digit_list
    |> Enum.slice((number_index - offset)..-1)
    |> Stream.with_index(number_index + 1)
    |> Stream.filter(fn {_n, list_i} ->
      pattern(list_i, number_index + 1) != 0
    end)
    |> Enum.reduce(0, fn {n, list_i}, acc ->
      m = pattern(list_i, number_index + 1)
      m * n + acc
    end)
    |> Kernel.rem(10)
    |> Kernel.abs()
  end

  defp pattern(list_index, number_index) do
    stream =
      @base_pattern
      |> Stream.cycle()
    Enum.at(stream, div(list_index, number_index))
  end
end

input = File.read!("input/16.txt")

Sixteen.one(input)
|> IO.inspect

Sixteen.two(input)
|> IO.inspect