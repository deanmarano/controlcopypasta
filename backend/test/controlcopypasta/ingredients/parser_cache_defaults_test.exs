defmodule Controlcopypasta.Ingredients.ParserCacheDefaultsTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.ParserCache
  alias Controlcopypasta.Ingredients.ReferenceData.Preparations

  # These assertions describe the fallback set that ParserCache uses when its
  # GenServer has not loaded the DB-backed vocabulary -- the state every release
  # `eval` script and every test that does not start the cache runs in. The two
  # lists were previously maintained by hand and had drifted in both directions.
  #
  # The cache is not started in this test, so ParserCache.preparations/0 and
  # preparation_metadata/0 return the compiled-in defaults.

  test "every reference-data preparation is in the fallback set" do
    fallback = ParserCache.default_preparations()

    missing =
      Preparations.default_preparations()
      |> Map.keys()
      |> Enum.reject(&MapSet.member?(fallback, &1))

    assert missing == [],
           "reference data defines preparations the fallback set lacks: #{inspect(missing)}"
  end

  test "British preparation words reach the fallback set" do
    fallback = ParserCache.default_preparations()

    for word <-
          ~w(deseeded de-seeded destoned stoned podded shelled scraped discarded undrained lengthways) do
      assert MapSet.member?(fallback, word),
             "#{word} missing from the fallback preparation set"
    end
  end

  test "tokenizer-only words are retained" do
    fallback = ParserCache.default_preparations()

    for word <-
          ~w(baked braised cut gutted scaled seasoned patted crosswise diagonally horizontally vertically) do
      assert MapSet.member?(fallback, word), "#{word} dropped from the fallback preparation set"
    end
  end

  test "fallback metadata covers every reference-data preparation" do
    meta = ParserCache.default_preparation_metadata()

    missing =
      Preparations.default_preparations()
      |> Map.keys()
      |> Enum.reject(&Map.has_key?(meta, &1))

    assert missing == [],
           "reference data defines preparations the fallback metadata lacks: #{inspect(missing)}"
  end
end
