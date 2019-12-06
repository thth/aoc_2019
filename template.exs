~w(One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve Thirteen Fourteen
Fifteen Sixteen Seventeen Eighteen Nineteen Twenty TwentyOne TwentyTwo TwentyThree
TwentyFour TwentyFive)
|> Enum.with_index()
|> Enum.each(fn {word, i} ->
  i = i |> Integer.to_string() |> String.pad_leading(2, "0")
  content =
    """
    defmodule #{word} do
      def one(input) do
        input
        |> parse()
      end

      def two(input) do
        input
        |> parse()
      end

      def parse(raw) do
        raw
      end
    end

    input = File.read!("input/#{i}.txt")

    #{word}.one(input)
    |> IO.inspect

    #{word}.two(input)
    |> IO.inspect
    """
  File.write!("#{i}.exs", content)
end)