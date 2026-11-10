defmodule Controlcopypasta.Ingredients.BritishPreparationsTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.ReferenceData.Preparations

  # These words were absent from the catalog, so they stayed in the ingredient
  # name and the name matched nothing:
  #   "1 red chilli deseeded and finely chopped" -> name "red chili deseeded"
  @added ~w(deseeded de-seeded destoned stoned podded shelled scraped
            discarded undrained lengthways lengthwise)

  test "each added preparation is in the default catalog" do
    defaults = Preparations.default_preparations()

    for word <- @added do
      assert Map.has_key?(defaults, word), "#{word} is missing from the preparation catalog"
    end
  end

  test "each added preparation has a verb and a valid category" do
    defaults = Preparations.default_preparations()

    for word <- @added do
      meta = Map.fetch!(defaults, word)
      assert is_binary(meta.verb) and meta.verb != "", "#{word} has no verb"
      assert meta.category in [:cut, :process], "#{word} has category #{inspect(meta.category)}"
    end
  end

  test "words that were already recognised are untouched" do
    defaults = Preparations.default_preparations()

    for word <- ~w(seeded pitted peeled drained chopped sliced) do
      assert Map.has_key?(defaults, word)
    end
  end
end
