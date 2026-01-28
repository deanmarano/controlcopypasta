defmodule Controlcopypasta.Ingredients.PendingIngredientWorker do
  @moduledoc """
  Oban worker that scans recipes for unmatched ingredients and queues them for review.

  This worker:
  1. Scans all recipes with ingredients
  2. Parses each ingredient using TokenParser
  3. Identifies ingredients that don't match any canonical
  4. Tracks frequency and sample texts
  5. Queues ingredients appearing 5+ times for admin review
  6. Optionally looks up FatSecret data to pre-populate suggestions
  """

  use Oban.Worker,
    queue: :scheduled,
    max_attempts: 3

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.{TokenParser, PendingIngredient}
  import Ecto.Query

  require Logger

  @min_occurrences 5
  @max_sample_texts 5

  # Single words that should never be queued as ingredients
  @blacklist_words ~w(
    about from more cups cup sticks stick pan
    ounces ounce tablespoons tablespoon teaspoons teaspoon
    one two three four five six seven eight nine ten
    and or if not using packed each grams leaves stemmed
    approximately roughly finely coarsely thinly thickly
    lightly firmly loosely tightly cut cleaned washed
    scrubbed split unpeeled additional total condiments
    peeled trimmed halved quartered diced sliced chopped
    minced crushed drained rinsed soaked thawed
    slightly tough husked hulled slices zest casings
    mortar husks melted softened sifted toasted
    strips kernels grater breasts minutes wedges
    thighs wings drumsticks legs drumstick thigh
    browned red pink white green yellow
    brine
  )

  # Multi-word phrases that should never be queued
  @blacklist_phrases [
    "at room temperature", "room temperature", "to taste", "as needed",
    "as desired", "cut into", "patted dry", "see tip", "see tips",
    "see note", "see notes", "juice of", "zest of",
    "for the pan", "the pan", "if needed", "if desired",
    "from about", "or more", "or less", "plus more",
    "for serving", "for garnish", "for topping",
    "for sprinkling", "for dusting", "for dipping", "for drizzling",
    "for coating", "for brushing", "for frying", "for greasing",
    "very finely", "very thinly", "percent fat",
    "on a diagonal", "pale green parts only", "pale-green parts only",
    "inch thick", "tough outer layers", "leaves picked",
    "star tip", "snail shells", "against the grain",
    "dark green parts", "large ears", "half of a",
    "pink liquid", "red liquid"
  ]

  # Prefixes - if name starts with any of these, skip it
  @blacklist_prefixes [
    "cut into ", "plus more ", "or more ", "see ",
    "for ", "to ", "into ", "on a ", "on the ",
    "each ", "until ", "about ", "well ", "through ",
    "from a ", "other ", "tied ", "two ", "three ", "four "
  ]

  @batch_size 5000

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("Starting pending ingredient scan...")

    lookup = Ingredients.build_ingredient_lookup()

    # Count total recipes
    total = Repo.one(
      from r in Recipe,
      where: fragment("jsonb_array_length(ingredients) > 0"),
      select: count(r.id)
    )

    Logger.info("Scanning #{total} recipes in batches of #{@batch_size}...")

    # Process in batches, collecting unique texts first then parsing
    unmatched = collect_unmatched_batched(total, lookup)

    # Filter to those meeting threshold and not blacklisted
    candidates = unmatched
    |> Enum.filter(fn {name, %{count: count}} ->
      count >= @min_occurrences and not blacklisted?(name)
    end)
    |> Enum.sort_by(fn {_, %{count: count}} -> -count end)

    Logger.info("Found #{length(candidates)} candidates meeting threshold")

    # Upsert into pending_ingredients
    inserted = upsert_pending(candidates)

    Logger.info("Upserted #{inserted} pending ingredients")

    {:ok, %{scanned: total, candidates: length(candidates), upserted: inserted}}
  end

  defp collect_unmatched_batched(total, lookup) do
    # First pass: collect all unique ingredient texts with their frequencies
    num_batches = div(total + @batch_size - 1, @batch_size)

    text_freq = Enum.reduce(0..(num_batches - 1), %{}, fn batch_num, acc ->
      offset = batch_num * @batch_size
      Logger.info("Processing batch #{batch_num + 1}/#{num_batches} (offset #{offset})...")

      recipes = Repo.all(
        from r in Recipe,
        where: fragment("jsonb_array_length(ingredients) > 0"),
        select: r.ingredients,
        offset: ^offset,
        limit: ^@batch_size
      )

      recipes
      |> Enum.flat_map(fn ings -> ings || [] end)
      |> Enum.reduce(acc, fn ing, inner_acc ->
        text = ing["text"]
        if text do
          Map.update(inner_acc, text, 1, &(&1 + 1))
        else
          inner_acc
        end
      end)
    end)

    Logger.info("Found #{map_size(text_freq)} unique ingredient texts, parsing...")

    # Second pass: parse each unique text once and aggregate unmatched names
    text_freq
    |> Enum.reduce(%{}, fn {text, freq}, acc ->
      parsed = TokenParser.parse(text, lookup: lookup)

      parsed.ingredients
      |> Enum.reject(& &1.canonical_name)
      |> Enum.reduce(acc, fn ingredient, inner_acc ->
        name = String.downcase(String.trim(ingredient.name))

        Map.update(inner_acc, name, %{count: freq, samples: [text]}, fn existing ->
          %{
            count: existing.count + freq,
            samples: Enum.take(Enum.uniq([text | existing.samples]), @max_sample_texts)
          }
        end)
      end)
    end)
  end

  @doc false
  def blacklisted?(name) do
    normalized = String.downcase(String.trim(name))

    normalized in @blacklist_words or
      normalized in @blacklist_phrases or
      Enum.any?(@blacklist_prefixes, &String.starts_with?(normalized, &1)) or
      # Too short (likely parsing artifact)
      String.length(normalized) < 3 or
      # Contains only numbers
      Regex.match?(~r/^\d+$/, normalized) or
      # Looks like a measurement or metric conversion
      Regex.match?(~r/^\d+["'-]/, normalized) or
      Regex.match?(~r/^cups?\/\d+/, normalized) or
      # Starts with articles
      String.starts_with?(normalized, ["a ", "an ", "the "]) or
      # Equipment words
      String.contains?(normalized, ["springform", "thermometer", "skillet"]) or
      # Contains slash with numbers (metric conversions like "cup/240")
      Regex.match?(~r/\/\d+$/, normalized) or
      # Measurement patterns like "1/2-inch", "1/2" thick", abbreviations like "oz.", "lb."
      Regex.match?(~r/^\d+\/?\d*-inch/, normalized) or
      Regex.match?(~r/^\d+\/?\d*"/, normalized) or
      Regex.match?(~r/^\d+%/, normalized) or
      Regex.match?(~r/^[a-z]{1,3}\.$/, normalized) or
      # Ends with "only" or "size" (usually prep descriptions)
      String.ends_with?(normalized, " only") or
      String.ends_with?(normalized, " size") or
      # Contains "online" (recipe references)
      String.contains?(normalized, "online") or
      # Unicode fractions (parsing artifacts)
      Regex.match?(~r/^[²³⁄₁₂₃₄₅₆₇₈₉₀]+$/, normalized) or
      # Contains instruction/description words
      String.contains?(normalized, "depending") or
      String.contains?(normalized, "and/or") or
      String.contains?(normalized, "diameter") or
      # Contains "-oz." or similar unit abbreviations with numbers
      Regex.match?(~r/\d+-?oz\./, normalized) or
      Regex.match?(~r/\d+-?lb\./, normalized)
  end

  defp upsert_pending(candidates) do

    candidates
    |> Enum.reduce(0, fn {name, %{count: count, samples: samples}}, acc ->
      attrs = %{
        name: name,
        occurrence_count: count,
        sample_texts: samples,
        suggested_display_name: titlecase(name)
      }

      case Repo.get_by(PendingIngredient, name: name) do
        nil ->
          %PendingIngredient{}
          |> PendingIngredient.changeset(attrs)
          |> Repo.insert()
          acc + 1

        existing ->
          # Only update if still pending
          if existing.status == "pending" do
            existing
            |> PendingIngredient.changeset(%{
              occurrence_count: count,
              sample_texts: Enum.take(Enum.uniq(samples ++ existing.sample_texts), @max_sample_texts)
            })
            |> Repo.update()
          end
          acc
      end
    end)
  end

  defp titlecase(name) do
    name
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @doc """
  Enqueues a job to scan for pending ingredients.
  """
  def enqueue do
    %{}
    |> __MODULE__.new()
    |> Oban.insert()
  end
end
