defmodule Eight do
  @image_width 25
  @image_height 6

  def one(input) do
    input
    |> parse()
    |> split_to_layers()
    |> Enum.min_by(fn layer -> Enum.count(layer, &(&1 == 0)) end)
    |> (fn layer ->
      Enum.count(layer, &(&1 == 1)) * Enum.count(layer, &(&1 == 2))
    end).()
  end

  def two(input) do
    input
    |> parse()
    |> split_to_layers()
    |> Enum.reduce(fn layer, acc ->
      Enum.zip(layer, acc)
      |> Enum.map(fn {bottom, top} ->
        if (top == 2), do: bottom, else: top
      end)
    end)
    |> Enum.chunk_every(@image_width)
    |> Enum.each(fn line ->
      line
      |> Enum.map(fn n -> if (n == 0), do: " ", else: "#" end)
      |> Enum.reduce(fn x, acc -> acc <> x end)
      |> IO.puts()
    end)
  end

  def parse(raw) do
    raw
    |> String.graphemes()
    |> Enum.map(&String.to_integer/1)
  end

  def split_to_layers(pixels) do
    Enum.chunk_every(pixels, @image_width * @image_height)
  end
end

input = File.read!("input/08.txt")

Eight.one(input)
|> IO.inspect

Eight.two(input)
