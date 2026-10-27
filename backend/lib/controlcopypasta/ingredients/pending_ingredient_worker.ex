defmodule Controlcopypasta.Ingredients.PendingIngredientWorker do
  @moduledoc """
  Scans recipes for unmatched ingredients and queues them for review.

  1. Scans all recipes with ingredients
  2. Parses each ingredient using TokenParser
  3. Identifies ingredients that don't match any canonical
  4. Tracks frequency and sample texts
  5. Queues every unmatched ingredient for admin review, ordered by frequency
  6. Records blacklist-rejected names as `rejected` with the rule that fired

  Every unmatched name is recorded. An earlier version only queued names seen
  5+ times and dropped everything a blacklist rule matched, which hid 61% of
  unmatched volume from review and left the `rejected` label with no rows at
  all -- so there was no way to tell a filtered parsing artifact from a real
  ingredient nobody had got to yet.
  """

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Ingredients
  alias Controlcopypasta.Ingredients.{TokenParser, PendingIngredient}
  import Ecto.Query

  require Logger

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
    brine with into warmed natural generous sub
    well off dry fire cool above below divided
    whole preferred inch inches pieces ends chunks
    dutch-process heated cooled reserved broken
    crusts cubed shaved pressed medium lumpy
    overnight mild-flavored you fat woody fronds
    deboned butterflied spatchcocked peeling packet
    sprigs raw add veggies crackers beans meal
    clove pound use broth divided fire turbinado
  )

  # Multi-word phrases that should never be queued
  @blacklist_phrases [
    "at room temperature",
    "room temperature",
    "to taste",
    "as needed",
    "as desired",
    "cut into",
    "patted dry",
    "see tip",
    "see tips",
    "see note",
    "see notes",
    "juice of",
    "zest of",
    "juice from",
    "zest from",
    "juice and zest",
    "fresh juice from juice",
    "for the pan",
    "the pan",
    "if needed",
    "if desired",
    "from about",
    "or more",
    "or less",
    "plus more",
    "for serving",
    "for garnish",
    "for topping",
    "for sprinkling",
    "for dusting",
    "for dipping",
    "for drizzling",
    "for coating",
    "for brushing",
    "for frying",
    "for greasing",
    "very finely",
    "very thinly",
    "percent fat",
    "on a diagonal",
    "pale green parts only",
    "pale-green parts only",
    "inch thick",
    "tough outer layers",
    "leaves picked",
    "star tip",
    "snail shells",
    "against the grain",
    "dark green parts",
    "large ears",
    "half of a",
    "pink liquid",
    "red liquid",
    # Salt measurement notes
    "use half as much by volume",
    "half as much by volume",
    # Temperature notes
    "at least 65°f",
    "at room temp",
    "at least 65",
    # Dietary notes
    "use gluten free if needed",
    "gluten free if needed",
    # Recipe reference patterns
    "recipe above",
    "reserved from above",
    "from above",
    # Preparation patterns
    "soaked overnight",
    "if lumpy",
    "sifted if lumpy",
    "whole preferred",
    "dutch-process or natural",
    # Citrus artifact patterns
    "juice from juice",
    "zest from zest",
    "lemon zest from zest",
    # King Arthur branded products (should be handled separately)
    "king arthur fiori di sicilia",
    "king arthur easy roll dough improver",
    "king arthur cinnamon sweet bits",
    "king arthur artisan bread topping",
    "king arthur harvest grains blend",
    "king arthur pie filling enhancer",
    "king arthur fruitcake fruit blend",
    "king arthur bread and cake enhancer",
    # Misc noise
    "any color",
    "medium scoops",
    "shaved with a vegetable peeler",
    "woody ends",
    "from the cob"
  ]

  # Prefixes - if name starts with any of these, skip it
  @blacklist_prefixes [
    "cut into ",
    "plus more ",
    "or more ",
    "see ",
    "for ",
    "to ",
    "into ",
    "on a ",
    "on the ",
    "each ",
    "until ",
    "about ",
    "well ",
    "through ",
    "from a ",
    "other ",
    "tied ",
    "two ",
    "three ",
    "four "
  ]

  @batch_size 5000
  @parse_chunk_size 5000

  def perform do
    Logger.info("Starting pending ingredient scan...")

    lookup = Ingredients.build_ingredient_lookup()

    # First pass: collect all unique ingredient texts with frequencies (fast)
    text_freq = collect_text_frequencies()

    Logger.info("Found #{map_size(text_freq)} unique ingredient texts, parsing incrementally...")

    # Second pass: parse in chunks and upsert incrementally
    texts = Enum.to_list(text_freq)
    total_texts = length(texts)
    chunks = Enum.chunk_every(texts, @parse_chunk_size)
    num_chunks = length(chunks)

    {total_upserted, _acc} =
      chunks
      |> Enum.with_index(1)
      |> Enum.reduce({0, %{}}, fn {chunk, chunk_num}, {_prev_upserted, acc} ->
        Logger.info(
          "Parsing chunk #{chunk_num}/#{num_chunks} (#{min(chunk_num * @parse_chunk_size, total_texts)}/#{total_texts} texts)..."
        )

        # Parse this chunk and accumulate unmatched
        acc =
          Enum.reduce(chunk, acc, fn {text, freq}, inner_acc ->
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

        # Record every unmatched name, not just the frequent ones. Names a
        # blacklist rule rejects are stored as "rejected" with the rule that
        # fired, so the filter's decisions become reviewable training labels
        # instead of being dropped silently.
        {rejected, candidates} =
          acc
          |> Enum.sort_by(fn {_, %{count: count}} -> -count end)
          |> Enum.split_with(fn {name, _} -> blacklisted?(name) end)

        inserted = upsert_pending(candidates)
        auto_rejected = upsert_rejected(rejected)

        Logger.info(
          "Chunk #{chunk_num}: #{inserted} candidates, #{auto_rejected} auto-rejected so far"
        )

        {inserted, acc}
      end)

    Logger.info("Scan complete: #{total_upserted} pending ingredients upserted")

    {:ok, %{total_texts: total_texts, upserted: total_upserted}}
  end

  defp collect_text_frequencies do
    total =
      Repo.one(
        from r in Recipe,
          where: fragment("jsonb_array_length(ingredients) > 0"),
          select: count(r.id)
      )

    num_batches = div(total + @batch_size - 1, @batch_size)
    Logger.info("Scanning #{total} recipes in #{num_batches} batches...")

    Enum.reduce(0..(num_batches - 1), %{}, fn batch_num, acc ->
      offset = batch_num * @batch_size
      Logger.info("Collecting texts batch #{batch_num + 1}/#{num_batches}...")

      recipes =
        Repo.all(
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

  @doc """
  Returns true when a name is filtered out by a blacklist rule.
  """
  def blacklisted?(name), do: rejection_rule(name) != nil

  @doc """
  Returns the name of the blacklist rule that rejects this ingredient name, or
  nil when nothing rejects it.

  The rule name is stored on the rejected record so that an auto-rejection is
  both attributable and reviewable: the rule that fired is the most useful
  feature for deciding whether the rule itself is wrong.
  """
  def rejection_rule(name) do
    normalized = String.downcase(String.trim(name))

    Enum.find_value(rejection_rules(), fn {rule, matches?} ->
      if matches?.(normalized), do: rule
    end)
  end

  defp rejection_rules do
    [
      {"blacklist_word", &(&1 in @blacklist_words)},
      {"blacklist_phrase", &(&1 in @blacklist_phrases)},
      {"blacklist_prefix", fn n -> Enum.any?(@blacklist_prefixes, &String.starts_with?(n, &1)) end},
      {"too_short", &(String.length(&1) < 3)},
      {"numeric_only", &Regex.match?(~r/^\d+$/, &1)},
      {"metric_weight", &Regex.match?(~r/^\d+([.,]\d+)?(g|kg|ml|l)$/i, &1)},
      {"metric_range", &Regex.match?(~r/^\d+g\s+to\s+\d+g$/i, &1)},
      {"leading_measurement", &Regex.match?(~r/^\d+["\'-]/, &1)},
      {"cup_conversion", &Regex.match?(~r/^cups?\/\d+/, &1)},
      {"leading_article", &String.starts_with?(&1, ["a ", "an ", "the "])},
      {"leading_unit", &starts_with_unit?(&1)},
      {"equipment_word", &String.contains?(&1, ["springform", "thermometer", "skillet"])},
      {"trailing_conversion", &Regex.match?(~r/\/\d+$/, &1)},
      {"inch_measurement", &Regex.match?(~r/^\d+\/?\d*-inch/, &1)},
      {"quote_measurement", &Regex.match?(~r/^\d+\/?\d*"/, &1)},
      {"percentage", &Regex.match?(~r/^\d+%/, &1)},
      {"abbreviation", &Regex.match?(~r/^[a-z]{1,3}\.$/, &1)},
      {"trailing_only", &String.ends_with?(&1, " only")},
      {"trailing_size", &String.ends_with?(&1, " size")},
      {"recipe_reference", &String.contains?(&1, "online")},
      {"unicode_fraction", &Regex.match?(~r/^[\x{00B2}\x{00B3}\x{2044}\x{2081}\x{2082}\x{2083}\x{2084}\x{2085}\x{2086}\x{2087}\x{2088}\x{2089}\x{2080}]+$/u, &1)},
      {"conditional_note", &String.contains?(&1, "depending")},
      {"and_or", &String.contains?(&1, "and/or")},
      {"diameter_note", &String.contains?(&1, "diameter")},
      {"oz_abbreviation", &Regex.match?(~r/\d+-?oz\./, &1)},
      {"lb_abbreviation", &Regex.match?(~r/\d+-?lb\./, &1)}
    ]
  end

  @unit_words ~w(
    tablespoon tablespoons tbsp tbs teaspoon teaspoons tsp
    cup cups ounce ounces oz pound pounds lb lbs
    pint pints quart quarts gallon gallons
    liter liters litre litres milliliter milliliters ml
    gram grams kilogram kilograms kg
    pinch pinches dash dashes bunch bunches
    sprig sprigs clove cloves slice slices piece pieces
    head heads stalk stalks can cans tin tins jar jars
    bottle bottles bag bags box boxes package packages
  )

  defp starts_with_unit?(name) do
    Enum.any?(@unit_words, fn unit ->
      name == unit or String.starts_with?(name, unit <> " ")
    end)
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
              sample_texts:
                Enum.take(Enum.uniq(samples ++ existing.sample_texts), @max_sample_texts)
            })
            |> Repo.update()
          end

          acc
      end
    end)
  end

  # Store blacklisted names as auto-rejected, tagged with the rule that fired.
  # Human decisions are never overwritten: only rows that are still pending, or
  # that a previous scan auto-rejected, are touched.
  defp upsert_rejected(rejected) do
    Enum.reduce(rejected, 0, fn {name, %{count: count, samples: samples}}, acc ->
      rule = rejection_rule(name)

      attrs = %{
        name: name,
        occurrence_count: count,
        sample_texts: samples,
        status: "rejected",
        rejected_by_rule: rule
      }

      case Repo.get_by(PendingIngredient, name: name) do
        nil ->
          %PendingIngredient{}
          |> PendingIngredient.changeset(attrs)
          |> Repo.insert()

          acc + 1

        %{status: "pending"} = existing ->
          existing |> PendingIngredient.changeset(attrs) |> Repo.update()
          acc + 1

        %{status: "rejected", reviewed_at: nil} = existing ->
          existing |> PendingIngredient.changeset(attrs) |> Repo.update()
          acc + 1

        _human_reviewed ->
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
  Runs a scan for pending ingredients asynchronously.
  """
  def enqueue do
    Task.start(fn -> perform() end)
  end
end
