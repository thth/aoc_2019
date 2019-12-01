~w(One Two Three Four Five Six Seven Eight Nine Ten Eleven Twelve Thirteen Fourteen
Fifteen Sixteen Seventeen Eighteen Nineteen Twenty TwentyOne TwentyTwo TwentyThree
TwentyFour TwentyFive)
|> Enum.with_index()
|> Enum.map(fn {w, i} ->
  {w, i |> Integer.to_string() |> String.pad_leading(2, "0")}
end)
|> Enum.each(fn {w, i} ->
  content =
    """
    defmodule #{w} do
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

    #{w}.one(input)
    |> IO.inspect

    #{w}.two(input)
    |> IO.inspect
    """
  File.write!("#{i}.exs", content)
end)