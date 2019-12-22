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

  defmodule Power do
    # translated from rosettacode's haskell modular exponentiation
    def power(b, e, m, r \\ 1)
    def power(_b, 0, _m, r), do: r
    def power(b, e, m, r) when rem(e, 2) == 1, do:
      power(rem(b * b, m), div(e, 2), m, rem(r * b, m))
    def power(b, e, m, r), do:
      power(rem(b * b, m), div(e, 2), m, r)
  end

  @one_deck 0..10006
  @one_card 2019

  @two_length 119_315_717_514_047
  @two_times 101_741_582_076_661
  @two_position 2020

  def one(input) do
    input
    |> parse()
    |> shuffle(@one_deck)
    |> Enum.find_index(&(&1 == @one_card))
  end

  def two(input) do
    # i gave up; this is /u/mcpower_'s solution translated to elixir
    deck = {0, 1} # {offset, increment}
    shuffles = two_parse(input)
    {step_off, step_inc} =
      Enum.reduce(shuffles, deck, fn {f, args}, acc ->
        apply(__MODULE__, f, [acc, @two_length] ++ args)
      end)
    increment = Power.power(step_inc, @two_times, @two_length)
    offset = step_off * (1 - increment) * inv(rem(1 - step_inc, @two_length), @two_length)
    offset = rem(offset, @two_length)

    rem(get(offset, increment, @two_position, @two_length) + @two_length, @two_length)
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

  defp shuffle(functions, deck) do
    Enum.reduce(functions, deck, fn {fun, args}, acc ->
      apply(Deck, fun, [acc | args])
    end)
  end

  def two_parse(raw) do
    raw
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&i_give_up_parse/1)
  end

  defp i_give_up_parse(string) do
    cond do
      string == "deal into new stack" ->
        {:i_give_up_stack, []}
      String.match?(string, ~r/^cut/) ->
        number =
          string
          |> String.split(" ")
          |> List.last()
          |> Integer.parse()
          |> elem(0)
        {:i_give_up_cut, [number]}
      String.match?(string, ~r/^deal with/) ->
        number =
          string
          |> String.split(" ")
          |> List.last()
          |> Integer.parse()
          |> elem(0)
        {:i_give_up_increment, [number]}
    end
  end

  def i_give_up_stack({offset, increment}, deck_length)  do
    new_increment = rem(-increment, deck_length)
    new_offset = rem(offset + new_increment, deck_length)
    {new_offset, new_increment}
  end

  def i_give_up_cut({offset, increment}, _deck_length, n) do
    new_offset = offset + (n * increment)
    {new_offset, increment}
  end

  def i_give_up_increment({offset, increment}, deck_length, n) do
    new_increment = rem(increment * inv(n, deck_length), deck_length)
    {offset, new_increment}
  end

  defp inv(n, deck_length) do
    Power.power(n, deck_length - 2, deck_length)
  end

  defp get(offset, increment, i, deck_length) do
    rem(offset + (i * increment), deck_length)
  end
end

input = File.read!("input/22.txt")

TwentyTwo.one(input)
|> IO.inspect

TwentyTwo.two(input)
|> IO.inspect