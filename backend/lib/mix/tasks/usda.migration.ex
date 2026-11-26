defmodule Mix.Tasks.Usda.Migration do
  @shortdoc "Generate a migration from reviewed USDA picks"

  @moduledoc """
  Turns a reviewed list of FoodData Central picks into a migration.

  The picks file is the record of which record a human chose for each
  ingredient, one per line:

      light brown sugar\t168833\tSugars, brown
      cheddar\t328637\tCheese, cheddar

  The third column is a description, kept so the file reads as a decision log
  and so a wrong pick is visible in review rather than only as an id. It is
  compared against what the API returns and the task refuses to continue if
  they disagree -- an id that silently started pointing at a different food
  would otherwise write the wrong numbers.

      mix usda.migration --picks priv/repo/usda/picks.tsv

  Values are written into the migration as literals, with `source_id` and
  `source_url` on every row, so the data is reproducible from the repository
  and production never calls the API. Same shape as
  `20261110040000_ship_missing_canonical_ingredients.exs`.

  Rows are inserted only where the ingredient has none, so re-running is safe.
  """

  use Mix.Task

  alias Controlcopypasta.Nutrition.Usda.{Client, Mapper}
  alias Controlcopypasta.Repo

  @requirements ["app.start"]

  # Units we store count weights under. A portion whose unit is not one of
  # these is skipped: the converter would not look it up anyway, and writing
  # "slice (1 oz)" as a unit would never match a parsed line.
  @useful_portion_units %{
    "cup" => "cup",
    "tbsp" => "tbsp",
    "tsp" => "tsp",
    "slice" => "slice",
    "sprig" => "sprig",
    "bunch" => "bunch",
    "head" => "head",
    # FDC names a whole fennel or garlic by its bulb, and the stored lines
    # count them bare ("1 small fennel bulb"), which parses as a count of one.
    "bulb" => "each",
    "clove" => "each",
    "stalk" => "stalk",
    "leaf" => "leaf",
    "fillet" => "fillet",
    "piece" => "piece",
    "block" => "block"
  }

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} = OptionParser.parse(argv, strict: [picks: :string, out: :string])
    picks_path = opts[:picks] || Mix.raise("--picks is required")

    unless Client.configured?() do
      Mix.raise("USDA_API_KEY is not set.")
    end

    picks = read_picks(picks_path)
    Mix.shell().info("Fetching #{length(picks)} reviewed pick(s)...")

    entries = Enum.map(picks, &fetch/1)

    case Enum.filter(entries, &match?({:error, _, _}, &1)) do
      [] -> :ok
      errors -> Mix.raise("refusing to generate:\n" <> Enum.map_join(errors, "\n", &describe/1))
    end

    ok = Enum.map(entries, fn {:ok, entry} -> entry end)
    out = opts[:out] || default_out()
    File.mkdir_p!(Path.dirname(out))
    File.write!(out, migration_source(ok, Path.basename(out)))

    # Generated code still has to satisfy `mix format --check-formatted`, and
    # getting the blank lines between statements right by hand in a heredoc is
    # not worth it.
    Mix.Task.run("format", [out])

    nutrition = Enum.count(ok, & &1.nutrition)
    densities = ok |> Enum.flat_map(& &1.densities) |> length()

    Mix.shell().info("""

    Wrote #{out}
      #{nutrition} nutrition row(s)
      #{densities} density row(s)
    """)
  end

  defp read_picks(path) do
    path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> Enum.reject(&(String.starts_with?(&1, "#") or String.trim(&1) == ""))
    |> Enum.map(fn line ->
      case String.split(line, "\t") do
        [name, fdc_id, description] ->
          %{
            name: String.trim(name),
            fdc_id: String.trim(fdc_id),
            description: String.trim(description)
          }

        _ ->
          Mix.raise("bad picks line (expected name<TAB>fdcId<TAB>description):\n  #{line}")
      end
    end)
  end

  defp fetch(%{name: name, fdc_id: fdc_id, description: expected}) do
    with {:ok, canonical_id} <- canonical_id(name),
         {:ok, food} <- Client.food(fdc_id),
         :ok <- check_description(food, expected, name) do
      nutrition =
        case Mapper.nutrition_attrs(food) do
          {:ok, attrs} -> attrs
          {:error, _} -> nil
        end

      {:ok,
       %{
         name: name,
         canonical_id: canonical_id,
         fdc_id: to_string(fdc_id),
         description: Map.get(food, "description"),
         nutrition: nutrition,
         densities: densities(food)
       }}
    else
      {:error, reason} -> {:error, name, reason}
    end
  end

  # Resolved here only to fail early on a name that does not exist. The id is
  # NOT written into the migration: canonical ingredient ids differ per
  # database, and embedding the dev ones produced a foreign key violation the
  # moment the migration ran anywhere else. The generated SQL joins on the
  # name instead, which is also what the existing
  # ship_missing_canonical_ingredients migration does.
  defp canonical_id(name) do
    case Repo.query!("SELECT id FROM canonical_ingredients WHERE name = $1", [name]) do
      %{rows: [[id]]} -> {:ok, Ecto.UUID.cast!(id)}
      %{rows: []} -> {:error, "no canonical ingredient named #{inspect(name)}"}
      %{rows: _} -> {:error, "several canonical ingredients named #{inspect(name)}"}
    end
  end

  # The pick file records which food was chosen. If the id now describes
  # something else, the review no longer applies to it.
  defp check_description(food, expected, name) do
    actual = Map.get(food, "description") || ""

    if String.downcase(String.trim(actual)) == String.downcase(expected) do
      :ok
    else
      {:error,
       "#{name}: picks file says #{inspect(expected)} but fdcId now returns #{inspect(actual)}"}
    end
  end

  defp densities(food) do
    food
    |> Mapper.portions()
    |> Enum.flat_map(fn %{unit: unit, grams_per_unit: grams} ->
      case Map.fetch(@useful_portion_units, normalize_portion_unit(unit)) do
        {:ok, stored_unit} -> [%{unit: stored_unit, grams_per_unit: Float.round(grams, 2)}]
        :error -> []
      end
    end)
    |> Enum.uniq_by(& &1.unit)
  end

  # FDC writes portions like "cup, chopped" or "tbsp, ground". The leading word
  # is the measure; the rest is a preparation we do not model per-density here.
  defp normalize_portion_unit(unit) do
    unit
    |> String.downcase()
    |> String.split(~r/[,(]/, parts: 2)
    |> hd()
    |> String.trim()
    |> String.trim_trailing("s")
  end

  defp describe({:error, name, reason}), do: "  #{name}: #{reason}"

  defp default_out do
    stamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%d%H%M%S")
    "priv/repo/migrations/#{stamp}_seed_usda_nutrition_and_densities.exs"
  end

  defp migration_source(entries, basename) do
    module =
      basename
      |> Path.rootname()
      |> String.split("_", parts: 2)
      |> List.last()
      |> Macro.camelize()

    """
    defmodule Controlcopypasta.Repo.Migrations.#{module} do
      use Ecto.Migration

      @moduledoc \"\"\"
      Nutrition and count/volume weights from USDA FoodData Central, for
      canonical ingredients that had none.

      Generated by `mix usda.migration` from a reviewed picks file. Every row
      carries its FDC id and URL, so each number can be traced back to the
      record it came from. The values are literals rather than a runtime fetch,
      so this is reproducible from the repository and the deployed application
      never calls the API.

      Rows are inserted only where the ingredient has none, so this is safe to
      re-run and will not overwrite a hand-curated value.
      \"\"\"

      def up do
    #{Enum.map_join(entries, "\n", &entry_source/1)}
      end

      def down do
        # Only the rows this migration added, identified by their source id.
        execute(\"\"\"
        DELETE FROM ingredient_nutrition
        WHERE source = 'usda' AND source_id IN (#{quoted_ids(entries)})
        \"\"\")

        execute(\"\"\"
        DELETE FROM ingredient_densities
        WHERE source = 'usda' AND source_id IN (#{quoted_ids(entries)})
        \"\"\")
      end
    end
    """
  end

  defp quoted_ids(entries) do
    entries |> Enum.map(&"'#{&1.fdc_id}'") |> Enum.uniq() |> Enum.join(", ")
  end

  defp entry_source(entry) do
    header = "    # #{entry.name} <- #{entry.description} (FDC #{entry.fdc_id})"

    [header, nutrition_source(entry), density_sources(entry)]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join("\n")
  end

  defp nutrition_source(%{nutrition: nil}), do: nil

  defp nutrition_source(entry) do
    attrs = entry.nutrition

    {columns, values} =
      attrs
      |> Map.drop([:source, :source_id, :source_name, :source_url])
      |> Enum.filter(fn {_k, v} -> is_number(v) or is_binary(v) end)
      |> Enum.sort()
      |> Enum.map_reduce([], fn {k, v}, acc -> {to_string(k), acc ++ [sql_literal(v)]} end)

    """
        execute(\"\"\"
        INSERT INTO ingredient_nutrition
          (id, canonical_ingredient_id, #{Enum.join(columns, ", ")},
           source, source_id, source_name, source_url, is_primary, confidence,
           retrieved_at, inserted_at, updated_at)
        SELECT gen_random_uuid(), c.id, #{Enum.join(values, ", ")},
               'usda', '#{entry.fdc_id}', #{sql_literal(attrs.source_name)}, #{sql_literal(attrs.source_url)},
               true, 0.95, NOW(), NOW(), NOW()
        FROM canonical_ingredients c
        WHERE c.name = #{sql_literal(entry.name)}
          AND NOT EXISTS (
            SELECT 1 FROM ingredient_nutrition n WHERE n.canonical_ingredient_id = c.id
          )
        \"\"\")\
    """
  end

  defp density_sources(%{densities: []}), do: nil

  defp density_sources(entry) do
    Enum.map_join(entry.densities, "\n", fn density ->
      """
          execute(\"\"\"
          INSERT INTO ingredient_densities
            (id, canonical_ingredient_id, volume_unit, grams_per_unit, source,
             source_id, source_url, confidence, retrieved_at, inserted_at, updated_at)
          SELECT gen_random_uuid(), c.id, '#{density.unit}',
                 #{density.grams_per_unit}, 'usda', '#{entry.fdc_id}',
                 #{sql_literal(entry.nutrition && entry.nutrition.source_url)}, 0.95, NOW(), NOW(), NOW()
          FROM canonical_ingredients c
          WHERE c.name = #{sql_literal(entry.name)}
            AND NOT EXISTS (
              SELECT 1 FROM ingredient_densities d
              WHERE d.canonical_ingredient_id = c.id AND d.volume_unit = '#{density.unit}'
            )
          \"\"\")\
      """
    end)
  end

  defp sql_literal(value) when is_number(value), do: to_string(value)
  defp sql_literal(nil), do: "NULL"

  defp sql_literal(value) when is_binary(value),
    do: "'" <> String.replace(value, "'", "''") <> "'"
end
