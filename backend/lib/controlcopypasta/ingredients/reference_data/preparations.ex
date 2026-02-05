defmodule Controlcopypasta.Ingredients.ReferenceData.Preparations do
  @moduledoc """
  Canonical preparation definitions with metadata.

  Delegates to ParserCache for DB-backed lookups at runtime.
  Falls back to hardcoded defaults when cache is not available
  (e.g., during seeding or testing without a running application).

  Single source of truth for:
  - Preparation word recognition
  - Verb forms for mise en place instructions
  - Time estimates and tool requirements
  - Categorization (cut, cook, process, temperature)
  """

  alias Controlcopypasta.Ingredients.ParserCache

  # Default preparations kept for seeding migrations and test fallback
  @default_preparations %{
    # Cutting preparations
    "diced" => %{verb: "dice", category: :cut, tool: "knife", time_per_cup: 2},
    "minced" => %{verb: "mince", category: :cut, tool: "knife", time_per_cup: 3},
    "julienned" => %{verb: "julienne", category: :cut, tool: "knife", time_per_cup: 5},
    "chopped" => %{verb: "chop", category: :cut, tool: "knife", time_per_cup: 1},
    "finely chopped" => %{verb: "finely chop", category: :cut, tool: "knife", time_per_cup: 2},
    "roughly chopped" => %{verb: "roughly chop", category: :cut, tool: "knife", time_per_cup: 1},
    "sliced" => %{verb: "slice", category: :cut, tool: "knife", time_per_cup: 1},
    "thinly sliced" => %{verb: "thinly slice", category: :cut, tool: "knife", time_per_cup: 2},
    "grated" => %{verb: "grate", category: :cut, tool: "grater", time_per_cup: 2},
    "shredded" => %{verb: "shred", category: :cut, tool: "grater", time_per_cup: 3},
    "cubed" => %{verb: "cube", category: :cut, tool: "knife", time_per_cup: 2},
    "halved" => %{verb: "halve", category: :cut, tool: "knife", time_per_item: 0.25},
    "quartered" => %{verb: "quarter", category: :cut, tool: "knife", time_per_item: 0.5},
    "crushed" => %{verb: "crush", category: :cut, tool: "knife", time_per_item: 0.25},
    "smashed" => %{verb: "smash", category: :cut, tool: "knife", time_per_item: 0.25},
    "crumbled" => %{verb: "crumble", category: :cut, tool: nil, time_per_cup: 1},
    "torn" => %{verb: "tear", category: :cut, tool: nil, time_per_cup: 1},

    # Temperature/State preparations
    "room temperature" => %{verb: "bring to room temperature", category: :temperature, time_min: 30},
    "softened" => %{verb: "soften", category: :temperature, time_min: 30},
    "melted" => %{verb: "melt", category: :temperature, time_min: 2},
    "chilled" => %{verb: "chill", category: :temperature, time_min: 60},
    "cooled" => %{verb: "cool", category: :temperature, time_min: 15},
    "thawed" => %{verb: "thaw", category: :temperature, time_min: 120},
    "frozen" => %{verb: "freeze", category: :temperature, time_min: 120},
    "warmed" => %{verb: "warm", category: :temperature, time_min: 2},
    "heated" => %{verb: "heat", category: :temperature, time_min: 2},

    # Pre-cooking preparations
    "cooked" => %{verb: "cook", category: :cook, time_min: 15},
    "toasted" => %{verb: "toast", category: :cook, time_min: 5},
    "roasted" => %{verb: "roast", category: :cook, time_min: 30},
    "blanched" => %{verb: "blanch", category: :cook, time_min: 3},
    "sauteed" => %{verb: "saute", category: :cook, time_min: 5},
    "sautéed" => %{verb: "saute", category: :cook, time_min: 5},
    "fried" => %{verb: "fry", category: :cook, time_min: 10},
    "boiled" => %{verb: "boil", category: :cook, time_min: 10},
    "steamed" => %{verb: "steam", category: :cook, time_min: 10},
    "grilled" => %{verb: "grill", category: :cook, time_min: 15},
    "hard-boiled" => %{verb: "hard-boil", category: :cook, time_min: 12},
    "poached" => %{verb: "poach", category: :cook, time_min: 5},
    "caramelized" => %{verb: "caramelize", category: :cook, time_min: 15},
    "browned" => %{verb: "brown", category: :cook, time_min: 5},

    # Processing preparations
    "drained" => %{verb: "drain", category: :process, time_min: 1},
    "rinsed" => %{verb: "rinse", category: :process, time_min: 1},
    "strained" => %{verb: "strain", category: :process, time_min: 1},
    "soaked" => %{verb: "soak", category: :process, time_min: 30},
    "dried" => %{verb: "dry", category: :process, time_min: 5},
    "peeled" => %{verb: "peel", category: :process, time_per_item: 0.5},
    "seeded" => %{verb: "seed", category: :process, time_per_item: 1},
    "cored" => %{verb: "core", category: :process, time_per_item: 0.5},
    "deveined" => %{verb: "devein", category: :process, time_per_item: 0.5},
    "pitted" => %{verb: "pit", category: :process, time_per_item: 0.25},
    "trimmed" => %{verb: "trim", category: :process, time_per_item: 0.25},
    "cleaned" => %{verb: "clean", category: :process, time_min: 2},
    "washed" => %{verb: "wash", category: :process, time_min: 1},
    "scrubbed" => %{verb: "scrub", category: :process, time_min: 2},
    "patted dry" => %{verb: "pat dry", category: :process, time_min: 1},
    "squeezed" => %{verb: "squeeze", category: :process, time_per_item: 0.5},
    "zested" => %{verb: "zest", category: :process, tool: "zester", time_per_item: 1},
    "juiced" => %{verb: "juice", category: :process, tool: "juicer", time_per_item: 0.5},
    "beaten" => %{verb: "beat", category: :process, tool: "whisk", time_min: 2},
    "whisked" => %{verb: "whisk", category: :process, tool: "whisk", time_min: 1},
    "separated" => %{verb: "separate", category: :process, time_per_item: 0.5},
    "sifted" => %{verb: "sift", category: :process, tool: "sifter", time_min: 1},
    "mashed" => %{verb: "mash", category: :process, tool: "masher", time_min: 3},
    "pureed" => %{verb: "puree", category: :process, tool: "blender", time_min: 2},
    "pressed" => %{verb: "press", category: :process, time_min: 1},
    "dissolved" => %{verb: "dissolve", category: :process, time_min: 1},
    "marinated" => %{verb: "marinate", category: :process, time_min: 30},
    "brined" => %{verb: "brine", category: :process, time_min: 60},
    "deboned" => %{verb: "debone", category: :process, time_per_item: 2},
    "shucked" => %{verb: "shuck", category: :process, time_per_item: 0.5},
    "stemmed" => %{verb: "stem", category: :process, time_per_item: 0.25},
    "destemmed" => %{verb: "destem", category: :process, time_per_item: 0.25},
    "scored" => %{verb: "score", category: :process, tool: "knife", time_per_item: 0.5},
    "segmented" => %{verb: "segment", category: :process, time_per_item: 2},
    "bundled" => %{verb: "bundle", category: :process, time_min: 1},
    "bruised" => %{verb: "bruise", category: :process, time_per_item: 0.25},

    # Descriptive states (no active prep needed)
    "removed" => %{verb: "remove", category: :process, time_min: 1},
    "divided" => %{verb: "divide", category: :process, time_min: 1},
    "packed" => %{verb: "pack", category: :process, time_min: 1}
  }

  @doc """
  Returns all preparation words (for tokenizer).
  """
  def all_preparations do
    ParserCache.preparations() |> MapSet.to_list()
  end

  @doc """
  Checks if a word is a known preparation.
  """
  def is_preparation?(nil), do: false
  def is_preparation?(word) when is_binary(word) do
    MapSet.member?(ParserCache.preparations(), String.downcase(word))
  end

  @doc """
  Gets the metadata for a preparation.

  Returns nil if preparation is not found.

  ## Examples

      iex> Preparations.get_metadata("diced")
      %{verb: "dice", category: :cut, tool: "knife", time_per_cup: 2}

      iex> Preparations.get_metadata("unknown")
      nil
  """
  def get_metadata(prep) when is_binary(prep) do
    Map.get(ParserCache.preparation_metadata(), String.downcase(prep))
  end
  def get_metadata(_), do: nil

  @doc """
  Gets the verb form for a preparation.

  ## Examples

      iex> Preparations.verb("diced")
      "dice"

      iex> Preparations.verb("unknown")
      nil
  """
  def verb(prep) do
    case get_metadata(prep) do
      %{verb: v} -> v
      _ -> nil
    end
  end

  @doc """
  Gets the category for a preparation.

  Categories: :cut, :cook, :process, :temperature

  ## Examples

      iex> Preparations.category("diced")
      :cut

      iex> Preparations.category("melted")
      :temperature
  """
  def category(prep) do
    case get_metadata(prep) do
      %{category: c} -> c
      _ -> :other
    end
  end

  @doc """
  Gets all preparations with their full metadata.

  Useful for PreStepGenerator.
  """
  def all_with_metadata do
    ParserCache.preparation_metadata()
  end

  @doc """
  Returns preparations that are cutting actions.
  """
  def cutting_preparations do
    ParserCache.preparation_metadata()
    |> Enum.filter(fn {_, meta} -> meta[:category] == :cut end)
    |> Enum.map(fn {prep, _} -> prep end)
  end

  @doc """
  Returns preparations that are temperature-related.
  """
  def temperature_preparations do
    ParserCache.preparation_metadata()
    |> Enum.filter(fn {_, meta} -> meta[:category] == :temperature end)
    |> Enum.map(fn {prep, _} -> prep end)
  end

  @doc """
  Returns the default preparations map (for seeding/testing).
  """
  def default_preparations, do: @default_preparations
end
