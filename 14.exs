defmodule Fourteen do
  @base "ORE"
  @end_product "FUEL"
  @base_quantity 1_000_000_000_000

  def one(input) do
    input
    |> parse()
    |> produce_chemical(@end_product)
    |> elem(0)
  end

  def two(input) do
    input
    |> parse()
    |> loop_until_over(@end_product, @base_quantity)
  end

  def parse(raw) do
    raw
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(fn line ->
      [ingredients_string, out_string] = String.split(line, "=>")
      [out_quantity_string, out] =
        out_string
        |> String.trim()
        |> String.split(" ")
      out_quantity = String.to_integer(out_quantity_string)

      ingredients_list =
        ingredients_string
        |> String.trim()
        |> String.split(", ")
        |> Enum.map(fn ing_string ->
          [ing_quantity_str, ing] = String.split(ing_string, " ")
          {ing, String.to_integer(ing_quantity_str)}
        end)

      {out, %{out_quantity: out_quantity, ingredients: ingredients_list}}
    end)
    |> Enum.into(%{})
  end

  defp loop_until_over(formulae, end_product, base_quantity, leftovers \\ %{}, base \\ 0, product_count \\ 0)
  defp loop_until_over(_formulae, _end_product, base_quantity, _leftovers, base, product_count)
    when base >= base_quantity, do: product_count - 1
  defp loop_until_over(formulae, end_product, base_quantity, leftovers, base, product_count) do
    {base_used, new_leftovers} = produce_chemical(formulae, end_product, leftovers)
    loop_until_over(formulae, end_product, base_quantity, new_leftovers, base + base_used, product_count + 1)
  end

  defp produce_chemical(formulae, end_product, leftovers \\ %{}, end_quantity \\ 1) do
    output_quantity = Map.get(formulae, end_product).out_quantity
    multiple_needed = calculate_multiple_needed(end_quantity, output_quantity)
    need_stack = Enum.map(formulae[end_product].ingredients, fn {ingredient, quantity} ->
      {ingredient, quantity * multiple_needed}
    end)
    loop_production(formulae, leftovers, need_stack)
  end

  defp loop_production(formulae, leftovers, need_stack, base_count \\ 0)
  defp loop_production(_formulae, leftovers, [], base_count), do: {base_count, leftovers}
  defp loop_production(formulae, leftovers, [{@base, qty_needed} | rest_stack], base_count), do:
    loop_production(formulae, leftovers, rest_stack, base_count + qty_needed)
  defp loop_production(formulae, leftovers, [{chemical, qty_needed} | rest_stack], base_count) do
    if Map.get(leftovers, chemical, 0) >= qty_needed do
      new_leftovers = Map.update!(leftovers, chemical, &(&1 - qty_needed))
      loop_production(formulae, new_leftovers, rest_stack, base_count)
    else
      remaining_qty_needed = qty_needed - Map.get(leftovers, chemical, 0)
      output_quantity = formulae[chemical].out_quantity
      multiple_needed = calculate_multiple_needed(remaining_qty_needed, output_quantity)
      leftover_quantity = Map.get(leftovers, chemical, 0) + (output_quantity * multiple_needed) - qty_needed
      new_leftovers = Map.put(leftovers, chemical, leftover_quantity)
      stack_additions =
        formulae[chemical].ingredients
        |> Enum.map(fn {ing, q} -> {ing, q * multiple_needed} end)
      loop_production(formulae, new_leftovers, stack_additions ++ rest_stack, base_count)
    end
  end

  defp calculate_multiple_needed(quantity_needed, output_quantity) do
    round(Float.ceil(quantity_needed / output_quantity))
  end
end

input = File.read!("input/14.txt")

Fourteen.one(input)
|> IO.inspect

Fourteen.two(input)
|> IO.inspect
