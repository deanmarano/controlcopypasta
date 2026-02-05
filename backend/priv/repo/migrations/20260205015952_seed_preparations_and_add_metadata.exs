defmodule Controlcopypasta.Repo.Migrations.SeedPreparationsAndAddMetadata do
  use Ecto.Migration

  def up do
    # Add verb and metadata columns to preparations table
    alter table(:preparations) do
      add :verb, :string
      add :metadata, :map, default: %{}
    end

    flush()

    # Seed preparations from the union of all known preparation sources.
    # This is the combined set from:
    # - ReferenceData.Preparations (~90 entries with full metadata)
    # - Tokenizer @preparations (~70 entries)
    # - TokenParser @prep_indicators (~43 entries)
    # Deduped by name.

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    preparations = all_preparations()

    Enum.each(preparations, fn prep ->
      execute("""
      INSERT INTO preparations (id, name, display_name, category, verb, metadata, aliases, inserted_at, updated_at)
      VALUES (
        gen_random_uuid(),
        #{escape(prep.name)},
        #{escape(prep.display_name)},
        #{escape(prep.category)},
        #{escape(prep.verb)},
        #{escape_json(prep.metadata)},
        #{escape_array(prep.aliases)},
        '#{now}',
        '#{now}'
      )
      ON CONFLICT (name) DO UPDATE SET
        verb = COALESCE(EXCLUDED.verb, preparations.verb),
        metadata = COALESCE(EXCLUDED.metadata, preparations.metadata),
        category = COALESCE(EXCLUDED.category, preparations.category)
      """)
    end)
  end

  def down do
    # Remove seeded data
    execute("DELETE FROM preparations")

    alter table(:preparations) do
      remove :verb
      remove :metadata
    end
  end

  defp escape(nil), do: "NULL"
  defp escape(str) when is_binary(str) do
    "'#{String.replace(str, "'", "''")}'"
  end

  defp escape_json(nil), do: "'{}'"
  defp escape_json(map) when is_map(map) do
    "'#{String.replace(Jason.encode!(map), "'", "''")}'"
  end

  defp escape_array(nil), do: "ARRAY[]::varchar[]"
  defp escape_array([]), do: "ARRAY[]::varchar[]"
  defp escape_array(list) when is_list(list) do
    items = Enum.map_join(list, ", ", fn item ->
      "'#{String.replace(item, "'", "''")}'"
    end)
    "ARRAY[#{items}]::varchar[]"
  end

  # Combined preparation data from all sources
  defp all_preparations do
    # Reference data preparations (with full metadata)
    reference_data = %{
      "diced" => %{verb: "dice", category: "cut", tool: "knife", time_per_cup: 2},
      "minced" => %{verb: "mince", category: "cut", tool: "knife", time_per_cup: 3},
      "julienned" => %{verb: "julienne", category: "cut", tool: "knife", time_per_cup: 5},
      "chopped" => %{verb: "chop", category: "cut", tool: "knife", time_per_cup: 1},
      "finely chopped" => %{verb: "finely chop", category: "cut", tool: "knife", time_per_cup: 2},
      "roughly chopped" => %{verb: "roughly chop", category: "cut", tool: "knife", time_per_cup: 1},
      "sliced" => %{verb: "slice", category: "cut", tool: "knife", time_per_cup: 1},
      "thinly sliced" => %{verb: "thinly slice", category: "cut", tool: "knife", time_per_cup: 2},
      "grated" => %{verb: "grate", category: "cut", tool: "grater", time_per_cup: 2},
      "shredded" => %{verb: "shred", category: "cut", tool: "grater", time_per_cup: 3},
      "cubed" => %{verb: "cube", category: "cut", tool: "knife", time_per_cup: 2},
      "halved" => %{verb: "halve", category: "cut", tool: "knife", time_per_item: 0.25},
      "quartered" => %{verb: "quarter", category: "cut", tool: "knife", time_per_item: 0.5},
      "crushed" => %{verb: "crush", category: "cut", tool: "knife", time_per_item: 0.25},
      "smashed" => %{verb: "smash", category: "cut", tool: "knife", time_per_item: 0.25},
      "crumbled" => %{verb: "crumble", category: "cut", time_per_cup: 1},
      "torn" => %{verb: "tear", category: "cut", time_per_cup: 1},
      # Temperature/State
      "room temperature" => %{verb: "bring to room temperature", category: "temperature", time_min: 30},
      "softened" => %{verb: "soften", category: "temperature", time_min: 30},
      "melted" => %{verb: "melt", category: "temperature", time_min: 2},
      "chilled" => %{verb: "chill", category: "temperature", time_min: 60},
      "cooled" => %{verb: "cool", category: "temperature", time_min: 15},
      "thawed" => %{verb: "thaw", category: "temperature", time_min: 120},
      "frozen" => %{verb: "freeze", category: "temperature", time_min: 120},
      "warmed" => %{verb: "warm", category: "temperature", time_min: 2},
      "heated" => %{verb: "heat", category: "temperature", time_min: 2},
      # Pre-cooking
      "cooked" => %{verb: "cook", category: "heat", time_min: 15},
      "toasted" => %{verb: "toast", category: "heat", time_min: 5},
      "roasted" => %{verb: "roast", category: "heat", time_min: 30},
      "blanched" => %{verb: "blanch", category: "heat", time_min: 3},
      "sauteed" => %{verb: "saute", category: "heat", time_min: 5},
      "sautéed" => %{verb: "saute", category: "heat", time_min: 5},
      "fried" => %{verb: "fry", category: "heat", time_min: 10},
      "boiled" => %{verb: "boil", category: "heat", time_min: 10},
      "steamed" => %{verb: "steam", category: "heat", time_min: 10},
      "grilled" => %{verb: "grill", category: "heat", time_min: 15},
      "hard-boiled" => %{verb: "hard-boil", category: "heat", time_min: 12},
      "poached" => %{verb: "poach", category: "heat", time_min: 5},
      "caramelized" => %{verb: "caramelize", category: "heat", time_min: 15},
      "browned" => %{verb: "brown", category: "heat", time_min: 5},
      # Processing
      "drained" => %{verb: "drain", category: "process", time_min: 1},
      "rinsed" => %{verb: "rinse", category: "process", time_min: 1},
      "strained" => %{verb: "strain", category: "process", time_min: 1},
      "soaked" => %{verb: "soak", category: "process", time_min: 30},
      "dried" => %{verb: "dry", category: "process", time_min: 5},
      "peeled" => %{verb: "peel", category: "process", time_per_item: 0.5},
      "seeded" => %{verb: "seed", category: "process", time_per_item: 1},
      "cored" => %{verb: "core", category: "process", time_per_item: 0.5},
      "deveined" => %{verb: "devein", category: "process", time_per_item: 0.5},
      "pitted" => %{verb: "pit", category: "process", time_per_item: 0.25},
      "trimmed" => %{verb: "trim", category: "process", time_per_item: 0.25},
      "cleaned" => %{verb: "clean", category: "process", time_min: 2},
      "washed" => %{verb: "wash", category: "process", time_min: 1},
      "scrubbed" => %{verb: "scrub", category: "process", time_min: 2},
      "patted dry" => %{verb: "pat dry", category: "process", time_min: 1},
      "squeezed" => %{verb: "squeeze", category: "process", time_per_item: 0.5},
      "zested" => %{verb: "zest", category: "process", tool: "zester", time_per_item: 1},
      "juiced" => %{verb: "juice", category: "process", tool: "juicer", time_per_item: 0.5},
      "beaten" => %{verb: "beat", category: "process", tool: "whisk", time_min: 2},
      "whisked" => %{verb: "whisk", category: "process", tool: "whisk", time_min: 1},
      "separated" => %{verb: "separate", category: "process", time_per_item: 0.5},
      "sifted" => %{verb: "sift", category: "process", tool: "sifter", time_min: 1},
      "mashed" => %{verb: "mash", category: "process", tool: "masher", time_min: 3},
      "pureed" => %{verb: "puree", category: "process", tool: "blender", time_min: 2},
      "pressed" => %{verb: "press", category: "process", time_min: 1},
      "dissolved" => %{verb: "dissolve", category: "process", time_min: 1},
      "marinated" => %{verb: "marinate", category: "process", time_min: 30},
      "brined" => %{verb: "brine", category: "process", time_min: 60},
      "deboned" => %{verb: "debone", category: "process", time_per_item: 2},
      "shucked" => %{verb: "shuck", category: "process", time_per_item: 0.5},
      "stemmed" => %{verb: "stem", category: "process", time_per_item: 0.25},
      "destemmed" => %{verb: "destem", category: "process", time_per_item: 0.25},
      "scored" => %{verb: "score", category: "process", tool: "knife", time_per_item: 0.5},
      "segmented" => %{verb: "segment", category: "process", time_per_item: 2},
      "bundled" => %{verb: "bundle", category: "process", time_min: 1},
      "bruised" => %{verb: "bruise", category: "process", time_per_item: 0.25},
      "removed" => %{verb: "remove", category: "process", time_min: 1},
      "divided" => %{verb: "divide", category: "process", time_min: 1},
      "packed" => %{verb: "pack", category: "process", time_min: 1},
      # Tokenizer-only preps (no detailed metadata in reference data)
      "patted" => %{verb: "pat", category: "process"},
      # TokenParser @prep_indicators that aren't already covered
      "scaled" => %{verb: "scale", category: "process"},
      "gutted" => %{verb: "gut", category: "process"},
      "seasoned" => %{verb: "season", category: "process"},
      "baked" => %{verb: "bake", category: "heat"},
      "braised" => %{verb: "braise", category: "heat"},
      "cut" => %{verb: "cut", category: "cut"}
    }

    # Additional words from tokenizer @preparations not in reference_data
    tokenizer_only = ~w(lengthwise crosswise diagonally horizontally vertically)

    # Build the full list
    entries =
      Enum.map(reference_data, fn {name, meta} ->
        # Extract verb and put rest into metadata
        {verb, rest} = Map.pop(meta, :verb)
        {category, rest} = Map.pop(rest, :category)

        %{
          name: name,
          display_name: titlecase(name),
          category: category,
          verb: verb,
          metadata: if(map_size(rest) > 0, do: stringify_keys(rest), else: nil),
          aliases: []
        }
      end)

    # Add tokenizer-only words (directional modifiers)
    tokenizer_entries =
      Enum.map(tokenizer_only, fn name ->
        %{
          name: name,
          display_name: titlecase(name),
          category: "other",
          verb: nil,
          metadata: nil,
          aliases: []
        }
      end)

    entries ++ tokenizer_entries
  end

  defp titlecase(name) do
    name
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp stringify_keys(map) do
    Map.new(map, fn {k, v} -> {Atom.to_string(k), v} end)
  end
end
