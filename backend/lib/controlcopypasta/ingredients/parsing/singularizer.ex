defmodule Controlcopypasta.Ingredients.Parsing.Singularizer do
  @moduledoc """
  Conservative English word singularization for ingredient parsing.

  Uses pattern-based rules to convert plural forms to singular,
  with exceptions for words that naturally end in 's' or have
  irregular pluralization.
  """

  # Words that should not be singularized (naturally end in 's' or are exceptions)
  @no_singularize ~w(
    hummus couscous asparagus molasses cilantro
    jus floss glass grass moss
    Swiss swiss dress press
  )

  @doc """
  Attempts to singularize an English word.

  Uses conservative rules to avoid breaking words that naturally end in 's'.
  Returns the word unchanged if it's in the exception list or doesn't match
  any known plural patterns.

  ## Examples

      iex> Singularizer.singularize("tomatoes")
      "tomato"

      iex> Singularizer.singularize("berries")
      "berry"

      iex> Singularizer.singularize("leaves")
      "leaf"

      iex> Singularizer.singularize("carrots")
      "carrot"

      iex> Singularizer.singularize("hummus")
      "hummus"
  """
  def singularize(word) when is_binary(word) do
    downcased = String.downcase(word)

    cond do
      # Don't singularize short words or words in exception list
      String.length(word) < 3 -> word
      downcased in @no_singularize -> word

      # -ves -> -f (leaves -> leaf, halves -> half, loaves -> loaf)
      String.ends_with?(downcased, "ves") ->
        String.slice(word, 0..-4//1) <> "f"

      # -ies -> -y (berries -> berry, anchovies -> anchovy)
      String.ends_with?(downcased, "ies") ->
        String.slice(word, 0..-4//1) <> "y"

      # -sses -> -ss (molasses stays, but grasses -> grass)
      String.ends_with?(downcased, "sses") ->
        word

      # -shes -> -sh (radishes -> radish)
      String.ends_with?(downcased, "shes") ->
        String.slice(word, 0..-3//1)

      # -ches -> -ch (peaches -> peach)
      String.ends_with?(downcased, "ches") ->
        String.slice(word, 0..-3//1)

      # -xes -> -x (boxes -> box)
      String.ends_with?(downcased, "xes") ->
        String.slice(word, 0..-3//1)

      # -zes -> -z (fizzes handled by -sses above)
      String.ends_with?(downcased, "zes") ->
        String.slice(word, 0..-3//1)

      # -toes -> -to (tomatoes -> tomato, potatoes -> potato)
      String.ends_with?(downcased, "toes") ->
        String.slice(word, 0..-3//1)

      # -oes -> -o (but keep heroes -> hero pattern)
      String.ends_with?(downcased, "oes") ->
        String.slice(word, 0..-3//1)

      # -s (general plural, but not -ss, -us)
      String.ends_with?(downcased, "s") and
        not String.ends_with?(downcased, "ss") and
        not String.ends_with?(downcased, "us") ->
        String.slice(word, 0..-2//1)

      true -> word
    end
  end

  def singularize(nil), do: nil

  @doc """
  Returns the list of words that should not be singularized.
  """
  def exceptions, do: @no_singularize
end
