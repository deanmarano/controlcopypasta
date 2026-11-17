defmodule Controlcopypasta.Ingredients.ParserCache do
  @moduledoc """
  GenServer that loads parser vocabulary from the database into `:persistent_term`
  for O(1) reads with no copying.

  Cached data:
  - `:parser_preparations` → MapSet of preparation words (for tokenizer/token_parser)
  - `:parser_preparation_metadata` → %{name => %{verb, category, tool, ...}} (for PreStepGenerator)
  - `:parser_normalizer` → %{variant_name => canonical_form} (for IngredientNormalizer)

  Call `refresh!/0` after admin edits to reload from DB.
  """

  use GenServer
  require Logger

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Ingredients.{Preparation, CanonicalIngredient}

  # ── Default Fallbacks (merged with DB data; also used before DB is available) ──

  # Words the tokenizer treats as preparations when the DB-backed cache has not
  # been loaded. This list used to be maintained by hand alongside
  # ReferenceData.Preparations, and the two drifted in both directions: the
  # reference data gained 18 entries this list never got (including every
  # British form added for the ~3,700 lines that recorded "deseeded" as part of
  # the ingredient name), while this list held 11 words the reference data never
  # had. Deriving the set from the reference data plus an explicit extras list
  # makes that drift impossible.
  #
  # It matters only outside a running application -- `prep_set` below unions
  # these with the DB, so a started ParserCache is unaffected -- but release
  # `eval` scripts and tests that never start the cache parse with this set
  # alone, and a word missing here is silently extracted as an ingredient name.
  @tokenizer_only_preparations ~w(
    baked braised cut gutted scaled seasoned patted
    crosswise diagonally horizontally vertically
  )

  @default_preparations Controlcopypasta.Ingredients.ReferenceData.Preparations.default_preparations()
                        |> Map.keys()
                        |> Enum.concat(@tokenizer_only_preparations)
                        |> MapSet.new()
  # Same drift as @default_preparations above: this map was a hand-maintained
  # subset holding 62 of the reference data's 90 entries, with no keys of its
  # own. Taking the reference data directly keeps the verbs and timings used by
  # PreStepGenerator in step with the catalog.
  @default_preparation_metadata Controlcopypasta.Ingredients.ReferenceData.Preparations.default_preparations()

  @default_normalizer_map %{
    # Normalized as a phrase, not an alias: "shredded" is labelled a preparation
    # and stripped, so by the time the matcher runs only "coconut" is left -- and
    # bare "coconut" cannot be aliased to the flakes, because in
    # "grapeseed, coconut, or avocado oil" it means the oil.
    "shredded coconut" => "coconut flakes",
    "desiccated coconut" => "coconut flakes",
    "flaked coconut" => "coconut flakes",
    "all-purpose flour" => "flour",
    "all purpose flour" => "flour",
    "ap flour" => "flour",
    "granulated sugar" => "sugar",
    "white sugar" => "sugar",
    "caster sugar" => "sugar",
    "confectioners sugar" => "powdered sugar",
    "confectioners' sugar" => "powdered sugar",
    "icing sugar" => "powdered sugar",
    "light brown sugar" => "brown sugar",
    "dark brown sugar" => "brown sugar",
    "unsalted butter" => "butter",
    "salted butter" => "butter",
    "canola oil" => "vegetable oil",
    "extra virgin olive oil" => "olive oil",
    "extra-virgin olive oil" => "olive oil",
    "evoo" => "olive oil",
    "whole milk" => "milk",
    "2% milk" => "milk",
    "skim milk" => "milk",
    "heavy whipping cream" => "heavy cream",
    "whipping cream" => "heavy cream",
    "half-and-half" => "half and half",
    "plain yogurt" => "yogurt",
    "eggs" => "egg",
    "egg whites" => "egg white",
    "egg yolks" => "egg yolk",
    "kosher salt" => "salt",
    "sea salt" => "salt",
    "table salt" => "salt",
    "flaky salt" => "salt",
    "bicarbonate of soda" => "baking soda",
    "active dry yeast" => "yeast",
    "instant yeast" => "yeast",
    "vanilla extract" => "vanilla",
    "pure vanilla extract" => "vanilla",
    "vanilla paste" => "vanilla",
    "garlic clove" => "garlic",
    "garlic cloves" => "garlic",
    "onions" => "onion",
    "yellow onion" => "onion",
    "white onion" => "onion",
    "green onions" => "green onion",
    "scallion" => "green onion",
    "scallions" => "green onion",
    "shallots" => "shallot",
    "pepper" => "black pepper",
    "ground black pepper" => "black pepper",
    "freshly ground black pepper" => "black pepper",
    "cayenne pepper" => "cayenne",
    "crushed red pepper" => "red pepper flakes",
    "chicken breasts" => "chicken breast",
    "chicken thighs" => "chicken thigh",
    "chicken legs" => "chicken leg",
    "pork chops" => "pork chop",
    "tomatoes" => "tomato",
    "roma tomato" => "tomato",
    "cherry tomatoes" => "cherry tomato",
    "grape tomato" => "cherry tomato",
    "grape tomatoes" => "cherry tomato",
    "canned tomato" => "canned tomatoes",
    "diced tomatoes" => "canned tomatoes",
    "cheddar cheese" => "cheddar",
    "parmesan cheese" => "parmesan",
    "parmigiano-reggiano" => "parmesan",
    "mozzarella cheese" => "mozzarella",
    "feta cheese" => "feta",
    "coriander" => "cilantro",
    "chive" => "chives",
    "bay leaves" => "bay leaf",
    "ground cinnamon" => "cinnamon",
    "ground nutmeg" => "nutmeg",
    "ground cumin" => "cumin",
    "low sodium soy sauce" => "soy sauce",
    "tamari" => "soy sauce",
    "almonds" => "almond",
    "walnuts" => "walnut",
    "pecans" => "pecan",
    "peanuts" => "peanut",
    "cashews" => "cashew",
    "pistachios" => "pistachio",
    "lemons" => "lemon",
    "limes" => "lime",
    "oranges" => "orange",
    "carrots" => "carrot",
    "potatoes" => "potato",
    "bell peppers" => "bell pepper",
    "cucumbers" => "cucumber",
    "mushrooms" => "mushroom"
  }

  # ── Public API ──────────────────────────────────────────────────────

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  The compiled-in preparation vocabulary used when the cache has not loaded.

  Exposed so the drift between this set and the reference data is testable
  without stopping the cache, which would race every other async test.
  """
  def default_preparations, do: @default_preparations

  @doc """
  The compiled-in preparation metadata used when the cache has not loaded.
  """
  def default_preparation_metadata, do: @default_preparation_metadata

  @doc """
  Returns a MapSet of all preparation words (for tokenizer/token_parser).
  Falls back to a hardcoded default if cache is not loaded.
  """
  def preparations do
    try do
      :persistent_term.get(:parser_preparations)
    rescue
      ArgumentError -> @default_preparations
    end
  end

  @doc """
  Returns a map of preparation name => metadata for PreStepGenerator.
  Falls back to a hardcoded default if cache is not loaded.
  """
  def preparation_metadata do
    try do
      :persistent_term.get(:parser_preparation_metadata)
    rescue
      ArgumentError -> @default_preparation_metadata
    end
  end

  @doc """
  Returns the normalizer map (%{variant => canonical_form}) for IngredientNormalizer.
  Falls back to a hardcoded default if cache is not loaded.
  """
  def normalizer_map do
    try do
      :persistent_term.get(:parser_normalizer)
    rescue
      ArgumentError -> @default_normalizer_map
    end
  end

  @doc """
  Checks if a word is a known ingredient name (exists in normalizer as key or value).

  This is useful for disambiguating words that could be both units and ingredients,
  like "cloves" (unit of garlic) vs "cloves" (the spice).

  Uses O(1) lookup via a pre-built MapSet of all known ingredient names.
  """
  def is_known_ingredient?(word) when is_binary(word) do
    normalized = String.downcase(word)

    ingredient_names =
      try do
        :persistent_term.get(:parser_ingredient_names)
      rescue
        ArgumentError -> MapSet.new()
      end

    MapSet.member?(ingredient_names, normalized)
  end

  @doc """
  Reloads all cached data from the database.
  """
  def refresh! do
    GenServer.call(__MODULE__, :refresh)
  end

  # ── GenServer Callbacks ─────────────────────────────────────────────

  @impl true
  def init(_opts) do
    load_all()
    {:ok, %{}}
  end

  @impl true
  def handle_call(:refresh, _from, state) do
    load_all()
    {:reply, :ok, state}
  end

  # ── Private ─────────────────────────────────────────────────────────

  defp load_all do
    load_preparations()
    load_normalizer()

    Logger.info(
      "ParserCache loaded: #{MapSet.size(preparations())} preparations, #{map_size(normalizer_map())} normalizer entries"
    )
  rescue
    e ->
      Logger.warning("ParserCache failed to load from DB, using defaults: #{inspect(e)}")
  end

  defp load_preparations do
    preps =
      Preparation
      |> select([p], {p.name, p.aliases, p.verb, p.category, p.metadata})
      |> Repo.all()

    # Build MapSet of all preparation names + aliases, merged with defaults
    db_prep_set =
      preps
      |> Enum.flat_map(fn {name, aliases, _verb, _category, _metadata} ->
        [name | aliases || []]
      end)
      |> MapSet.new()

    prep_set = MapSet.union(@default_preparations, db_prep_set)

    # Build metadata map: name => %{verb, category, tool, ...}
    # Start with defaults, overlay DB data (DB takes priority)
    db_metadata_map =
      preps
      |> Enum.flat_map(fn {name, aliases, verb, category, metadata} ->
        meta = build_meta(verb, category, metadata)

        entries = [{name, meta}]
        alias_entries = Enum.map(aliases || [], &{&1, meta})
        entries ++ alias_entries
      end)
      |> Map.new()

    metadata_map = Map.merge(@default_preparation_metadata, db_metadata_map)

    :persistent_term.put(:parser_preparations, prep_set)
    :persistent_term.put(:parser_preparation_metadata, metadata_map)
  end

  defp build_meta(verb, category, metadata) do
    base = %{}
    base = if verb, do: Map.put(base, :verb, verb), else: base
    base = if category, do: Map.put(base, :category, atomize_category(category)), else: base

    # Merge metadata fields (tool, time_per_cup, time_min, etc.)
    case metadata do
      %{} = meta when map_size(meta) > 0 ->
        meta
        |> Enum.reduce(base, fn {key, val}, acc ->
          Map.put(acc, String.to_existing_atom(key), val)
        end)

      _ ->
        base
    end
  rescue
    ArgumentError ->
      # String.to_existing_atom can fail for unknown atoms - use to_atom as fallback
      base = %{}
      base = if verb, do: Map.put(base, :verb, verb), else: base
      base = if category, do: Map.put(base, :category, atomize_category(category)), else: base

      case metadata do
        %{} = meta when map_size(meta) > 0 ->
          Enum.reduce(meta, base, fn {key, val}, acc ->
            Map.put(acc, String.to_atom(key), val)
          end)

        _ ->
          base
      end
  end

  defp atomize_category(nil), do: :other
  defp atomize_category("cut"), do: :cut
  defp atomize_category("heat"), do: :heat
  defp atomize_category("cook"), do: :cook
  defp atomize_category("temperature"), do: :temperature
  defp atomize_category("process"), do: :process
  defp atomize_category("measure"), do: :measure
  defp atomize_category("other"), do: :other
  defp atomize_category(cat), do: String.to_atom(cat)

  defp load_normalizer do
    # Build normalizer from canonical_ingredients with similarity_name
    # plus aliases that map to a different canonical form
    db_entries =
      CanonicalIngredient
      |> select([ci], {ci.name, ci.aliases, ci.similarity_name})
      |> Repo.all()
      |> Enum.flat_map(fn {name, aliases, similarity_name} ->
        # If ingredient has a similarity_name, map its name to that
        base = if similarity_name, do: [{name, similarity_name}], else: []

        # Map all aliases to the canonical ingredient name
        alias_entries =
          (aliases || [])
          |> Enum.map(fn alias_name -> {alias_name, similarity_name || name} end)

        base ++ alias_entries
      end)
      |> Map.new()

    # Merge: start with defaults, overlay DB data (DB takes priority)
    entries = Map.merge(@default_normalizer_map, db_entries)

    # Build a set of all known ingredient names (keys + values) for fast lookups
    all_names = MapSet.new(Map.keys(entries) ++ Map.values(entries))

    :persistent_term.put(:parser_normalizer, entries)
    :persistent_term.put(:parser_ingredient_names, all_names)
  end
end
