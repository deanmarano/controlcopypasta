defmodule Controlcopypasta.Ingredients.Detection.EquipmentDetector do
  @moduledoc """
  Detects kitchen equipment mentions in ingredient lines.

  Some recipe ingredient lists include equipment items like:
  - "A thermometer"
  - "An instant-read thermometer"
  - "Cheesecloth for straining"

  These should be filtered out as they are not actual ingredients.
  """

  # Kitchen equipment and tools
  @equipment_words ~w(
    thermometer thermometers
    mill mills
    pan pans
    cutter cutters
    skewer skewers
    cheesecloth
    mortar pestle
    grater graters
    peeler peelers
    strainer strainers
    colander colanders
    sieve sieves
    whisk whisks
    spatula spatulas
    ladle ladles
    tongs
    mandoline mandolines
    zester zesters
    reamer reamers
    juicer juicers
    blender blenders
    processor processors
    mixer mixers
    fryer fryers
    torch torches
    brush brushes
    rack racks
    sheet sheets
    parchment
    springform
    bundt
    skillet skillets
    saucepan saucepans
    pot pots
    bowl bowls
    platter platters
    towel towels
    timer timers
    scale scales
    measuring
    foil
    wrap
    twine
    string
    toothpick toothpicks
    probe
  )

  # Multi-word equipment phrases
  @equipment_phrases [
    "baking sheet",
    "sheet pan",
    "muffin tin",
    "loaf pan",
    "pie dish",
    "casserole dish",
    "dutch oven",
    "roasting pan",
    "air fryer",
    "instant pot",
    "food processor",
    "stand mixer",
    "hand mixer",
    "immersion blender",
    "kitchen twine",
    "parchment paper",
    "aluminum foil",
    "plastic wrap",
    "paper towels",
    "kitchen towels",
    "meat thermometer",
    "candy thermometer",
    "instant-read thermometer",
    "deep-fry thermometer",
    "deep fry thermometer",
    "barbecue tongs",
    "barbecue kit",
    "baking spray",
    "cooking spray",
    "nonstick spray",
    "spice mill",
    "mortar and pestle",
    "weber barbecue",
    "weber chimney",
    "pastry brush"
  ]

  @doc """
  Checks if text represents kitchen equipment rather than an ingredient.

  Returns true if the text appears to be equipment.

  ## Detection Rules

  1. Text starting with "A " or "An " followed by equipment word
  2. Text that is primarily an equipment phrase

  ## Examples

      iex> EquipmentDetector.is_equipment?("A thermometer")
      true

      iex> EquipmentDetector.is_equipment?("An instant-read thermometer")
      true

      iex> EquipmentDetector.is_equipment?("2 cups flour")
      false

      iex> EquipmentDetector.is_equipment?("1 lb chicken breast")
      false
  """
  def is_equipment?(nil), do: false
  def is_equipment?(text) when is_binary(text) do
    normalized = String.downcase(text)

    cond do
      # Pattern 1: Starts with "a" or "an" followed by equipment word/phrase
      Regex.match?(~r/^an?\s+/i, text) ->
        contains_equipment_word?(normalized) or contains_equipment_phrase?(normalized)
      # Pattern 2: Contains a known equipment phrase
      contains_equipment_phrase?(normalized) -> true
      # Pattern 3: Just an equipment word by itself (no quantity)
      not Regex.match?(~r/^\d/, text) and pure_equipment_word?(normalized) -> true
      true -> false
    end
  end

  @doc """
  Returns all equipment words (for external use if needed).
  """
  def equipment_words, do: @equipment_words

  @doc """
  Returns all equipment phrases (for external use if needed).
  """
  def equipment_phrases, do: @equipment_phrases

  # Check if text contains any equipment word
  defp contains_equipment_word?(text) do
    Enum.any?(@equipment_words, fn word ->
      String.contains?(text, word)
    end)
  end

  # Check if text contains any equipment phrase
  defp contains_equipment_phrase?(text) do
    Enum.any?(@equipment_phrases, fn phrase ->
      String.contains?(text, phrase)
    end)
  end

  # Check if text is purely an equipment word (e.g., just "tongs", "skewers")
  defp pure_equipment_word?(text) do
    trimmed = String.trim(text)
    # Strip leading articles and brand names
    stripped = Regex.replace(~r/^(?:an?\s+|the\s+|weber\s+)/i, trimmed, "")
    words = String.split(stripped)
    length(words) <= 2 and Enum.any?(words, fn w -> w in @equipment_words end)
  end
end
