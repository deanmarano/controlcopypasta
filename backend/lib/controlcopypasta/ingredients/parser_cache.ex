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

  @default_preparations MapSet.new(~w(
    chopped diced minced sliced cubed julienned shredded grated
    crushed smashed halved quartered torn crumbled
    melted softened chilled cooled thawed frozen
    drained rinsed strained peeled seeded cored pitted trimmed deveined
    mashed pureed beaten whisked sifted
    toasted roasted
    removed packed divided
    lengthwise crosswise diagonally horizontally vertically
    bruised separated
    juiced zested
    warmed heated pressed bundled dissolved segmented destemmed
    blanched marinated brined deboned shucked
    washed stemmed cleaned scrubbed patted scored
    scaled gutted seasoned
    baked fried sauteed braised steamed grilled
    cut soaked boiled poached caramelized browned dried cooked
  ))

  @default_preparation_metadata %{
    "diced" => %{verb: "dice", category: :cut, tool: "knife", time_per_cup: 2},
    "minced" => %{verb: "mince", category: :cut, tool: "knife", time_per_cup: 3},
    "julienned" => %{verb: "julienne", category: :cut, tool: "knife", time_per_cup: 5},
    "chopped" => %{verb: "chop", category: :cut, tool: "knife", time_per_cup: 1},
    "sliced" => %{verb: "slice", category: :cut, tool: "knife", time_per_cup: 1},
    "grated" => %{verb: "grate", category: :cut, tool: "grater", time_per_cup: 2},
    "shredded" => %{verb: "shred", category: :cut, tool: "grater", time_per_cup: 3},
    "cubed" => %{verb: "cube", category: :cut, tool: "knife", time_per_cup: 2},
    "halved" => %{verb: "halve", category: :cut, tool: "knife", time_per_item: 0.25},
    "quartered" => %{verb: "quarter", category: :cut, tool: "knife", time_per_item: 0.5},
    "crushed" => %{verb: "crush", category: :cut, tool: "knife", time_per_item: 0.25},
    "smashed" => %{verb: "smash", category: :cut, tool: "knife", time_per_item: 0.25},
    "crumbled" => %{verb: "crumble", category: :cut, time_per_cup: 1},
    "torn" => %{verb: "tear", category: :cut, time_per_cup: 1},
    "softened" => %{verb: "soften", category: :temperature, time_min: 30},
    "melted" => %{verb: "melt", category: :temperature, time_min: 2},
    "chilled" => %{verb: "chill", category: :temperature, time_min: 60},
    "cooled" => %{verb: "cool", category: :temperature, time_min: 15},
    "thawed" => %{verb: "thaw", category: :temperature, time_min: 120},
    "frozen" => %{verb: "freeze", category: :temperature, time_min: 120},
    "warmed" => %{verb: "warm", category: :temperature, time_min: 2},
    "heated" => %{verb: "heat", category: :temperature, time_min: 2},
    "toasted" => %{verb: "toast", category: :cook, time_min: 5},
    "roasted" => %{verb: "roast", category: :cook, time_min: 30},
    "blanched" => %{verb: "blanch", category: :cook, time_min: 3},
    "drained" => %{verb: "drain", category: :process, time_min: 1},
    "rinsed" => %{verb: "rinse", category: :process, time_min: 1},
    "strained" => %{verb: "strain", category: :process, time_min: 1},
    "peeled" => %{verb: "peel", category: :process, time_per_item: 0.5},
    "seeded" => %{verb: "seed", category: :process, time_per_item: 1},
    "cored" => %{verb: "core", category: :process, time_per_item: 0.5},
    "deveined" => %{verb: "devein", category: :process, time_per_item: 0.5},
    "pitted" => %{verb: "pit", category: :process, time_per_item: 0.25},
    "trimmed" => %{verb: "trim", category: :process, time_per_item: 0.25},
    "mashed" => %{verb: "mash", category: :process, tool: "masher", time_min: 3},
    "pureed" => %{verb: "puree", category: :process, tool: "blender", time_min: 2},
    "beaten" => %{verb: "beat", category: :process, tool: "whisk", time_min: 2},
    "whisked" => %{verb: "whisk", category: :process, tool: "whisk", time_min: 1},
    "sifted" => %{verb: "sift", category: :process, tool: "sifter", time_min: 1},
    "separated" => %{verb: "separate", category: :process, time_per_item: 0.5},
    "pressed" => %{verb: "press", category: :process, time_min: 1},
    "dissolved" => %{verb: "dissolve", category: :process, time_min: 1},
    "marinated" => %{verb: "marinate", category: :process, time_min: 30},
    "brined" => %{verb: "brine", category: :process, time_min: 60},
    "deboned" => %{verb: "debone", category: :process, time_per_item: 2},
    "shucked" => %{verb: "shuck", category: :process, time_per_item: 0.5},
    "cleaned" => %{verb: "clean", category: :process, time_min: 2},
    "washed" => %{verb: "wash", category: :process, time_min: 1},
    "scrubbed" => %{verb: "scrub", category: :process, time_min: 2},
    "zested" => %{verb: "zest", category: :process, tool: "zester", time_per_item: 1},
    "juiced" => %{verb: "juice", category: :process, tool: "juicer", time_per_item: 0.5},
    "removed" => %{verb: "remove", category: :process, time_min: 1},
    "divided" => %{verb: "divide", category: :process, time_min: 1},
    "packed" => %{verb: "pack", category: :process, time_min: 1},
    "stemmed" => %{verb: "stem", category: :process, time_per_item: 0.25},
    "destemmed" => %{verb: "destem", category: :process, time_per_item: 0.25},
    "scored" => %{verb: "score", category: :process, tool: "knife", time_per_item: 0.5},
    "segmented" => %{verb: "segment", category: :process, time_per_item: 2},
    "bundled" => %{verb: "bundle", category: :process, time_min: 1},
    "bruised" => %{verb: "bruise", category: :process, time_per_item: 0.25},
    "soaked" => %{verb: "soak", category: :process, time_min: 30},
    "dried" => %{verb: "dry", category: :process, time_min: 5}
  }

  @default_normalizer_map %{
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
    Logger.info("ParserCache loaded: #{MapSet.size(preparations())} preparations, #{map_size(normalizer_map())} normalizer entries")
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

    :persistent_term.put(:parser_normalizer, entries)
  end
end
