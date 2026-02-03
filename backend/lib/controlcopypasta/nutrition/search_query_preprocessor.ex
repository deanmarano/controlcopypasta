defmodule Controlcopypasta.Nutrition.SearchQueryPreprocessor do
  @moduledoc """
  Preprocesses ingredient names for nutrition API searches.
  Cleans up common patterns that confuse search engines.

  ## Problem Patterns

  From analyzing failed ingredient lookups, common issues include:
  - Dual unit formats: "2 cups/256 grams all-purpose flour"
  - Parenthetical content: "sambal oelek (sriracha works, too)"
  - URLs/markdown links: "[pitas | https://...]"
  - Quantity prefixes: "1 inch piece fresh ginger"
  - Brand names: "King Arthur Fiori di Sicilia"
  - Equipment mixed in: "metal wooden toothpicks"

  ## Usage

      iex> preprocess("2 cups/256 grams all-purpose flour")
      "all-purpose flour"

      iex> search_variations("butter (salted, room temp)")
      ["butter", "unsalted butter"]
  """

  require Logger

  # Common brand names to strip from queries (case-insensitive)
  @brand_names ~w(
    kirkland costco trader\ joe's whole\ foods 365 kroger safeway
    classico barilla del\ monte hunts hunt's heinz kraft
    general\ mills kellogg's post quaker bob's\ red\ mill king\ arthur
    mccormick morton diamond\ crystal simply\ organic frontier
    miyoko's daiya follow\ your\ heart so\ delicious silk oatly
    ghirardelli baker's nestle hershey's lindt
    heinz french's grey\ poupon hellmann's best\ foods
    spectrum bragg eden california\ olive\ ranch
  )

  # Words indicating equipment, not food
  @equipment_words ~w(
    skewer skewers toothpick toothpicks rack racks pan pans pot pots
    sheet sheets foil parchment paper towel towels cloth cheesecloth
    thermometer timer strainer sieve colander blender processor
    mixer bowl bowls dish dishes plate plates
  )

  # Common modifiers to try removing for simpler searches
  @common_modifiers ~w(
    fresh dried organic raw cooked roasted toasted ground whole
    chopped minced diced sliced julienned grated shredded packed
    sifted melted softened room\ temperature cold frozen thawed
    unsalted salted low-sodium reduced-sodium
    extra-virgin virgin light extra pure
    boneless skinless bone-in skin-on
    large medium small mini extra-large jumbo
  )

  @doc """
  Primary preprocessing - returns cleaned query string.

  Applies all cleaning rules in order to produce a searchable query.

  ## Examples

      iex> preprocess("2 cups/256 grams all-purpose flour")
      "all-purpose flour"

      iex> preprocess("butter (salted, room temp)")
      "butter"

      iex> preprocess("[pitas | https://www.example.com/recipe]")
      "pitas"
  """
  def preprocess(nil), do: nil
  def preprocess(""), do: ""

  def preprocess(name) when is_binary(name) do
    name
    |> String.trim()
    |> remove_markdown_links()
    |> remove_urls()
    |> remove_html_entities()
    |> remove_dual_units()
    |> remove_leading_quantities()
    |> remove_parenthetical_content()
    |> remove_trailing_notes()
    |> remove_brand_names()
    |> normalize_whitespace()
    |> String.trim()
  end

  @doc """
  Returns list of search variations to try in order.

  First is the preprocessed name, followed by progressively simpler forms.
  Use with display_name as a fallback option.

  ## Examples

      iex> search_variations("all-purpose flour", nil)
      ["all-purpose flour", "flour"]

      iex> search_variations("fresh basil leaves", "basil")
      ["fresh basil leaves", "basil leaves", "basil"]
  """
  def search_variations(name, display_name \\ nil)

  def search_variations(nil, nil), do: []
  def search_variations("", nil), do: []

  def search_variations(name, display_name) do
    # Start with preprocessed name
    preprocessed = preprocess(name)

    # Generate variations
    variations = [
      preprocessed,
      display_name && preprocess(display_name),
      without_modifiers(preprocessed),
      simplified_name(preprocessed),
      first_significant_word(preprocessed)
    ]

    # Remove nil, empty strings, and duplicates while preserving order
    variations
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
    |> Enum.take(5)  # Limit to 5 variations to avoid too many API calls
  end

  @doc """
  Checks if the ingredient name appears to be equipment rather than food.

  ## Examples

      iex> equipment?("metal wooden toothpicks")
      true

      iex> equipment?("chicken breast")
      false
  """
  def equipment?(name) when is_binary(name) do
    words = name |> String.downcase() |> String.split(~r/\s+/)
    equipment_set = MapSet.new(@equipment_words)

    # Check if any significant word is equipment
    Enum.any?(words, &MapSet.member?(equipment_set, &1))
  end

  def equipment?(_), do: false

  # Private cleaning functions

  # Remove markdown-style links: [text | url] or [text](url)
  defp remove_markdown_links(text) do
    text
    # [text | url] format (used in some recipe sites)
    |> String.replace(~r/\[([^\]|]+)\s*\|\s*[^\]]+\]/, "\\1")
    # [text](url) standard markdown format
    |> String.replace(~r/\[([^\]]+)\]\([^)]+\)/, "\\1")
  end

  # Remove standalone URLs
  defp remove_urls(text) do
    String.replace(text, ~r/https?:\/\/[^\s\)]+/, "")
  end

  # Remove HTML entities like &#8217;
  defp remove_html_entities(text) do
    text
    |> String.replace(~r/&#\d+;/, "")
    |> String.replace(~r/&[a-z]+;/i, "")
  end

  # Remove dual unit patterns like "2 cups/256 grams" or "3/4 cup/85 grams"
  # Keep the ingredient name that follows
  defp remove_dual_units(text) do
    # Pattern: quantity unit/quantity unit ingredient
    # e.g., "2 cups/256 grams all-purpose flour" -> "all-purpose flour"
    # e.g., "1/2 cup/115 grams butter" -> "butter"
    text
    |> String.replace(
      ~r/^\s*[\d\/\.\s]+(?:cups?|tbsps?|tsps?|oz|ounces?|lbs?|pounds?|grams?|g|ml|liters?)\s*\/\s*[\d\/\.\s]+(?:cups?|tbsps?|tsps?|oz|ounces?|lbs?|pounds?|grams?|g|ml|liters?)\s+/i,
      ""
    )
    # Also handle "3/4 packed cup/3 ounces" style
    |> String.replace(
      ~r/^\s*[\d\/\.\s]+(?:packed\s+)?(?:cups?|tbsps?|tsps?|oz|ounces?)\s*\/\s*[\d\/\.\s]+(?:cups?|tbsps?|tsps?|oz|ounces?|grams?|g)\s+/i,
      ""
    )
  end

  # Remove leading quantities like "1 inch piece", "2-3 cups", "One 2-inch piece"
  defp remove_leading_quantities(text) do
    text
    # "One 2 1/2– to 3 1/2–pound (1.1 to 1.6kg) chicken" -> "chicken"
    |> String.replace(~r/^(?:one|two|three|four|five|six|seven|eight|nine|ten)\s+[\d\s\/\-–]+(?:to\s+[\d\s\/\-–]+)?(?:inch|pound|lb|ounce|oz|gram|g|kg|cm|mm)s?(?:\s*\([^)]+\))?\s+/i, "")
    # "2-3 cups bell pepper" -> "bell pepper"
    |> String.replace(~r/^[\d\s\/\-–\.]+(?:to\s+[\d\s\/\-–\.]+)?\s*(?:cups?|tbsps?|tsps?|oz|ounces?|lbs?|pounds?|grams?|g|ml|liters?|pieces?|inch(?:es)?|cm|mm)\s+/i, "")
    # "1 (4 ounce) jar" -> ""
    |> String.replace(~r/^[\d\s\/\-–\.]+\s*\([^)]+\)\s*(?:jar|can|package|bottle|bag|box|container)s?\s+(?:of\s+)?/i, "")
    # Simple leading numbers: "3 limes" -> "limes"
    |> String.replace(~r/^[\d\s\/\-–\.]+\s+(?!and\s)/, "")
  end

  # Remove parenthetical content like "(optional)", "(such as...)", "(I used...)"
  defp remove_parenthetical_content(text) do
    text
    # Remove nested parens first, then outer
    |> String.replace(~r/\(\([^)]*\)\)/i, "")
    |> String.replace(~r/\([^)]*\)/i, "")
    # Also handle double-paren markers like ((optional))
    |> String.replace(~r/\(\([^)]*\)\)/i, "")
  end

  # Remove trailing notes like ", optional" or ", for serving"
  defp remove_trailing_notes(text) do
    text
    |> String.replace(~r/,\s*(?:optional|for serving|for garnish|to taste|as needed|if desired|plus more.*|or more.*|or less.*)$/i, "")
    |> String.replace(~r/,\s*(?:halved|quartered|sliced|diced|chopped|minced|cut.*|peeled.*)$/i, "")
  end

  # Remove known brand names from the text
  defp remove_brand_names(text) do
    Enum.reduce(@brand_names, text, fn brand, acc ->
      # Case-insensitive replacement, match whole word
      pattern = ~r/\b#{Regex.escape(brand)}'?s?\b/i
      String.replace(acc, pattern, "")
    end)
  end

  # Normalize whitespace: collapse multiple spaces, trim
  defp normalize_whitespace(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  # Remove common modifiers for simpler search
  defp without_modifiers(text) do
    words = String.split(text, ~r/\s+/)
    modifiers_set = MapSet.new(@common_modifiers)

    filtered =
      words
      |> Enum.reject(fn word ->
        MapSet.member?(modifiers_set, String.downcase(word))
      end)

    case filtered do
      [] -> text  # Don't return empty string
      words -> Enum.join(words, " ")
    end
  end

  # Get simplified name: remove commas and everything after
  defp simplified_name(text) do
    text
    |> String.split(",")
    |> List.first()
    |> String.trim()
  end

  # Get first significant word(s) - skip articles and adjectives
  defp first_significant_word(text) do
    words = String.split(text, ~r/\s+/)
    skip_words = MapSet.new(~w(a an the some any of for with and or))
    modifiers_set = MapSet.new(@common_modifiers)

    significant =
      words
      |> Enum.reject(fn word ->
        lower = String.downcase(word)
        MapSet.member?(skip_words, lower) or MapSet.member?(modifiers_set, lower)
      end)

    case significant do
      [] -> text
      [word] -> word
      [w1, w2 | _] -> "#{w1} #{w2}"  # Take first two significant words
    end
  end
end
