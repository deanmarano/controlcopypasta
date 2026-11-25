defmodule Mix.Tasks.Usda.Candidates do
  @shortdoc "Propose USDA FoodData Central records for canonicals missing data"

  @moduledoc """
  Finds canonical ingredients with no nutrition (or no density) and proposes
  FoodData Central records for them, writing a JSON file for review.

  **This writes nothing to the database.** Picking the wrong record is the main
  risk in this workflow -- a search for "thyme" returns both `Thyme, fresh` and
  `Spices, thyme, dried`, which differ by roughly 10x per gram -- so the
  proposal is reviewed first and applied by a separate step.

      mix usda.candidates --kind nutrition --limit 40 --out /tmp/cand.json
      mix usda.candidates --names priv/repo/usda/wanted.txt --out /tmp/cand.json

  Options:

    * `--kind`  `nutrition` (default), `density`, or `both`
    * `--limit` how many canonicals to propose for (default 25)
    * `--names` a file of canonical names, one per line, instead of querying
    * `--out`   where to write the proposal (required)

  Needs `USDA_API_KEY` in the environment. The running application never calls
  this API; see `Controlcopypasta.Nutrition.Usda.Client`.
  """

  use Mix.Task

  alias Controlcopypasta.Nutrition.Usda.{Client, Mapper, Picker}
  alias Controlcopypasta.Repo

  @requirements ["app.start"]

  @impl Mix.Task
  def run(argv) do
    {opts, _, _} =
      OptionParser.parse(argv,
        strict: [kind: :string, limit: :integer, names: :string, out: :string]
      )

    out = opts[:out] || Mix.raise("--out is required")

    unless Client.configured?() do
      Mix.raise("USDA_API_KEY is not set. It belongs in the dev environment, not in production.")
    end

    kind = opts[:kind] || "nutrition"
    names = names_to_fill(opts[:names], kind, opts[:limit] || 25)

    Mix.shell().info("Proposing records for #{length(names)} canonical ingredient(s)...")

    proposals = Enum.map(names, &propose/1)

    File.write!(out, Jason.encode_to_iodata!(%{kind: kind, proposals: proposals}, pretty: true))

    {ready, review} = Enum.split_with(proposals, & &1.confident)

    Mix.shell().info("""

    Wrote #{out}
      #{length(ready)} with an unambiguous match
      #{length(review)} needing a decision (ambiguous or no result)

    Review the file before applying. Entries with "confident": false have
    either no candidate or several that differ in kind (fresh vs dried, raw vs
    cooked), which is exactly where a wrong pick does real damage.
    """)
  end

  defp names_to_fill(nil, kind, limit) do
    having =
      case kind do
        "nutrition" ->
          "NOT EXISTS (SELECT 1 FROM ingredient_nutrition n WHERE n.canonical_ingredient_id = c.id)"

        "density" ->
          "NOT EXISTS (SELECT 1 FROM ingredient_densities d WHERE d.canonical_ingredient_id = c.id)"

        "both" ->
          """
          (NOT EXISTS (SELECT 1 FROM ingredient_nutrition n WHERE n.canonical_ingredient_id = c.id)
           OR NOT EXISTS (SELECT 1 FROM ingredient_densities d WHERE d.canonical_ingredient_id = c.id))
          """

        other ->
          Mix.raise("unknown --kind #{inspect(other)}")
      end

    %{rows: rows} =
      Repo.query!("""
      SELECT c.name FROM canonical_ingredients c
      WHERE #{having} AND NOT c.skip_nutrition
      ORDER BY c.name LIMIT #{limit}
      """)

    Enum.map(rows, &hd/1)
  end

  defp names_to_fill(path, _kind, _limit) do
    path |> File.read!() |> String.split("\n", trim: true) |> Enum.map(&String.trim/1)
  end

  defp propose(name) do
    case Client.search(name) do
      {:ok, []} ->
        %{name: name, confident: false, reason: "no FoodData Central result", candidates: []}

      {:ok, foods} ->
        candidates =
          foods
          |> Enum.take(5)
          |> Enum.map(&summarise(&1, name))

        {confident, reason} = Picker.assess(name, candidates)

        %{
          name: name,
          confident: confident,
          reason: reason,
          suggested: if(confident, do: hd(candidates).fdc_id),
          candidates: candidates
        }

      {:error, reason} ->
        %{
          name: name,
          confident: false,
          reason: "lookup failed: #{inspect(reason)}",
          candidates: []
        }
    end
  end

  defp summarise(food, name) do
    detail =
      case Client.food(food["fdcId"]) do
        {:ok, full} -> full
        {:error, _} -> food
      end

    calories =
      case Mapper.nutrition_attrs(detail) do
        {:ok, attrs} -> attrs.calories
        {:error, _} -> nil
      end

    %{
      fdc_id: food["fdcId"],
      description: food["description"],
      data_type: food["dataType"],
      calories_per_100g: calories,
      portions: Mapper.portions(detail),
      exact_name_match: String.downcase(food["description"] || "") == String.downcase(name)
    }
  end
end
