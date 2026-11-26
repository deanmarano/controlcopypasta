defmodule Controlcopypasta.ShoppingLists.QuantityFormatTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.ShoppingLists.QuantityFormat

  defp fmt(value, unit \\ nil), do: QuantityFormat.format(Decimal.new(value), unit)

  test "writes whole numbers without a decimal point" do
    assert fmt("2") == "2"
    assert fmt("4.0") == "4"
    assert fmt("13.00", "tbsp") == "13"
  end

  test "writes common fractions as fractions" do
    assert fmt("0.50", "cup") == "½"
    assert fmt("0.25", "cup") == "¼"
    assert fmt("0.33", "cup") == "⅓"
    assert fmt("1.5", "cups") == "1 ½"
    assert fmt("2.75") == "2 ¾"
  end

  test "rounds up when a quantity falls between two fractions" do
    # 13 tbsp is 0.8125 cup, exactly between ¾ and ⅞
    assert fmt("0.8125", "cup") == "⅞"
    assert fmt("1.97", "cups") == "2"
  end

  test "never rounds a real amount down to nothing" do
    assert fmt("0.03", "tsp") == "⅛"
  end

  test "keeps decimals for metric units" do
    assert fmt("250", "g") == "250"
    assert fmt("0.50", "kg") == "0.5"
    assert fmt("12.345", "ml") == "12.35"
  end

  test "passes through quantities that are not decimals" do
    assert QuantityFormat.format(3) == "3"
  end
end
