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
    "see note", "see notes", "juice of", "zest of", "juice from",
    "zest from", "juice and zest",
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
  @parse_chunk_size 5000

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    Logger.info("Starting pending ingredient scan...")

    lookup = Ingredients.build_ingredient_lookup()

    # First pass: collect all unique ingredient texts with frequencies (fast)
    text_freq = collect_text_frequencies(lookup)

    Logger.info("Found #{map_size(text_freq)} unique ingredient texts, parsing incrementally...")

    # Second pass: parse in chunks and upsert incrementally
    texts = Enum.to_list(text_freq)
    total_texts = length(texts)
    chunks = Enum.chunk_every(texts, @parse_chunk_size)
    num_chunks = length(chunks)

    {total_upserted, unmatched} = chunks
    |> Enum.with_index(1)
    |> Enum.reduce({0, %{}}, fn {chunk, chunk_num}, {upserted_so_far, acc} ->
      Logger.info("Parsing chunk #{chunk_num}/#{num_chunks} (#{min(chunk_num * @parse_chunk_size, total_texts)}/#{total_texts} texts)...")

      # Parse this chunk and accumulate unmatched
      acc = Enum.reduce(chunk, acc, fn {text, freq}, inner_acc ->
        parsed = TokenParser.parse(text, lookup: lookup)

        parsed.ingredients
        |> Enum.reject(& &1.canonical_name)
        |> Enum.reduce(inner_acc, fn ingredient, name_acc ->
          name = String.downcase(String.trim(ingredient.name))

          Map.update(name_acc, name, %{count: freq, samples: [text]}, fn existing ->
            %{
              count: existing.count + freq,
              samples: Enum.take(Enum.uniq([text | existing.samples]), @max_sample_texts)
            }
          end)
        end)
      end)

      # Upsert candidates that meet threshold so far
      candidates = acc
      |> Enum.filter(fn {name, %{count: count}} ->
        count >= @min_occurrences and not blacklisted?(name)
      end)
      |> Enum.sort_by(fn {_, %{count: count}} -> -count end)

      inserted = upsert_pending(candidates)
      Logger.info("Chunk #{chunk_num}: #{inserted} candidates upserted so far")

      {inserted, acc}
    end)

    Logger.info("Scan complete: #{total_upserted} pending ingredients upserted")

    {:ok, %{total_texts: total_texts, upserted: total_upserted}}
  end

  defp collect_text_frequencies(lookup) do
    total = Repo.one(
      from r in Recipe,
      where: fragment("jsonb_array_length(ingredients) > 0"),
      select: count(r.id)
    )

    num_batches = div(total + @batch_size - 1, @batch_size)
    Logger.info("Scanning #{total} recipes in #{num_batches} batches...")

    Enum.reduce(0..(num_batches - 1), %{}, fn batch_num, acc ->
      offset = batch_num * @batch_size
      Logger.info("Collecting texts batch #{batch_num + 1}/#{num_batches}...")

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
      # Metric weights like "113g", "30ml", "1.5kg" (parenthetical equivalents)
      Regex.match?(~r/^\d+([.,]\d+)?(g|kg|ml|l)$/i, normalized) or
      # Metric weight ranges like "28g to 43g"
      Regex.match?(~r/^\d+g\s+to\s+\d+g$/i, normalized) or
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
