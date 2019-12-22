defmodule TwentyTwo do
  defmodule Deck do
    # modular inverse from rosettacode
    defmodule Modular do
      def extended_gcd(a, b) do
        {last_remainder, last_x} = extended_gcd(abs(a), abs(b), 1, 0, 0, 1)
        {last_remainder, last_x * (if a < 0, do: -1, else: 1)}
      end
     
      defp extended_gcd(last_remainder, 0, last_x, _, _, _), do: {last_remainder, last_x}
      defp extended_gcd(last_remainder, remainder, last_x, x, last_y, y) do
        quotient   = div(last_remainder, remainder)
        remainder2 = rem(last_remainder, remainder)
        extended_gcd(remainder, remainder2, x, last_x - quotient*x, y, last_y - quotient*y)
      end
     
      def inverse(e, et) do
        {_g, x} = extended_gcd(e, et)
        rem(x + et, et)
      end
    end

    def deal_stack(deck) do
      Enum.reverse(deck)
    end

    def cut(deck, n) do
      {front, back} = Enum.split(deck, n)
      back ++ front
    end

    def deal_increment(deck, n) do
      deck_length = deck |> Enum.to_list() |> length()
      order =
        0..(deck_length - 1)
        |> Stream.cycle()
        |> Stream.map(fn i -> rem(i * n, deck_length) end)
        |> Enum.take(deck_length)

      deck
      |> Enum.with_index()
      |> Enum.sort_by(fn {_card, i} -> Enum.at(order, i) end)
      |> Enum.map(fn {card, _i} -> card end)
    end

    def reverse_index_stack(i, deck_length) do
      (deck_length - 1) - i
    end

    def reverse_index_cut(i, deck_length, n) when n >= 0 do
      if i >= (deck_length - n) do
        i - deck_length + n
      else
        i + n
      end
    end
    def reverse_index_cut(i, deck_length, n) when n < 0 do
      reverse_index_cut(i, deck_length, deck_length + n)
    end

    def reverse_index_increment(i, deck_length, n) do
      rem(i * Modular.inverse(n, deck_length), deck_length)
    end
  end

  @one_deck 0..10006
  @one_card 2019

  # @two_length 119_315_717_514_047
  # @two_times 101_741_582_076_661
  # @two_position 2020

  @two_length 10007
  @two_times 10006
  # @two_position 1538

  # @two_length 10
  # @two_times 1
  # @two_position 7

  def one(input) do
    input
    |> parse()
    |> shuffle(@one_deck)
    |> Enum.find_index(&(&1 == @one_card))
  end

  def two(input) do
    input
    # |> two_parse()
    # |> reverse_find_index(@two_times, @two_length, @two_position)
    funs = two_parse(input)
    Enum.map(0..(@two_length - 1),
      &(reverse_find_index(funs, @two_times, @two_length, &1)))
  end

  def parse(raw) do
    raw
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&convert_to_function/1)
  end

  defp convert_to_function(string) do
    cond do
      string == "deal into new stack" ->
        {:deal_stack, []}
      String.match?(string, ~r/^cut/) ->
        number =
          string
          |> String.split(" ")
          |> List.last()
          |> Integer.parse()
          |> elem(0)
        {:cut, [number]}
      String.match?(string, ~r/^deal with/) ->
        number =
          string
          |> String.split(" ")
          |> List.last()
          |> Integer.parse()
          |> elem(0)
        {:deal_increment, [number]}
    end
  end

  def two_parse(raw) do
    raw
    |> String.trim()
    |> String.split("\n")
    |> Enum.reverse()
    |> Enum.map(&two_convert_to_function/1)
  end

  defp reverse_find_index(functions, times, deck_length, pos) do
    fun = fn x ->
      Enum.reduce(functions, x, fn {f, args}, acc ->
        apply(Deck, f, [acc, deck_length] ++ args)
      end)
    end
    do_times(pos, pos, fun, times)
  end

  defp do_times(original, value, fun, times, i \\ 0)
  defp do_times(_original, value, _fun, times, i) when times == i, do: value
  defp do_times(original, value, fun, times, i) do
    # if rem(i, 1_000_000) == 0, do: IO.inspect(i)
    # if value == original and i != 0 do
    #   IO.inspect(i, label: "???")
    #   :timer.sleep(1_000_000)
    # end
    do_times(original, fun.(value), fun, times, i + 1)
  end

  defp two_convert_to_function(string) do
    cond do
      string == "deal into new stack" ->
        {:reverse_index_stack, []}
      String.match?(string, ~r/^cut/) ->
        number =
          string
          |> String.split(" ")
          |> List.last()
          |> Integer.parse()
          |> elem(0)
        {:reverse_index_cut, [number]}
      String.match?(string, ~r/^deal with/) ->
        number =
          string
          |> String.split(" ")
          |> List.last()
          |> Integer.parse()
          |> elem(0)
        {:reverse_index_increment, [number]}
    end
  end

  defp shuffle(functions, deck) do
    Enum.reduce(functions, deck, fn {fun, args}, acc ->
      apply(Deck, fun, [acc | args])
    end)
  end
end

# input = File.read!("input/22.txt")
input =
  """
  deal with increment 7
  deal with increment 9
  cut -2
  """

# TwentyTwo.one(input)
# |> IO.inspect

TwentyTwo.two(input)
|> IO.inspect(charlists: :as_lists)