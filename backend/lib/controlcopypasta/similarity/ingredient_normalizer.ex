defmodule Controlcopypasta.Similarity.IngredientNormalizer do
  @moduledoc """
  Normalizes ingredient names to canonical forms for similarity matching.

  This handles:
  - Pluralization (eggs -> egg)
  - Common variations (all-purpose flour -> flour)
  - Brand names removal
  - Descriptor removal (large, small, fresh, etc.)
  """

  alias Controlcopypasta.Ingredients.ParserCache

  @doc """
  Normalizes an ingredient name to its canonical form.
  """
  @spec normalize(String.t()) :: String.t()
  def normalize(name) when is_binary(name) do
    normalized = name |> String.downcase() |> String.trim()
    normalizer = ParserCache.normalizer_map()

    # First check exact match
    case Map.get(normalizer, normalized) do
      nil ->
        # Try without common prefixes
        stripped = strip_descriptors(normalized)

        case Map.get(normalizer, stripped) do
          nil ->
            # Return the stripped version as the canonical name
            singularize(stripped)

          canonical ->
            canonical
        end

      canonical ->
        canonical
    end
  end

  @doc """
  Returns a similarity score (0.0 to 1.0) between two ingredient names.
  Uses canonical normalization and Levenshtein distance for fuzzy matching.
  """
  @spec similarity(String.t(), String.t()) :: float()
  def similarity(name1, name2) do
    canonical1 = normalize(name1)
    canonical2 = normalize(name2)

    cond do
      canonical1 == canonical2 ->
        1.0

      String.contains?(canonical1, canonical2) or String.contains?(canonical2, canonical1) ->
        0.8

      true ->
        # Levenshtein-based similarity
        max_len = max(String.length(canonical1), String.length(canonical2))

        if max_len == 0 do
          1.0
        else
          distance = levenshtein(canonical1, canonical2)
          max(0.0, 1.0 - distance / max_len)
        end
    end
  end

  # Simple Levenshtein distance implementation
  defp levenshtein(s1, s2) do
    s1_chars = String.graphemes(s1)
    s2_chars = String.graphemes(s2)

    {dist, _} =
      Enum.reduce(s1_chars, {0..length(s2_chars) |> Enum.to_list(), 0}, fn c1, {prev_row, i} ->
        current_row =
          Enum.reduce(Enum.with_index(s2_chars), [i + 1], fn {c2, j}, row ->
            cost = if c1 == c2, do: 0, else: 1

            val =
              Enum.min([
                Enum.at(row, j) + 1,
                Enum.at(prev_row, j + 1) + 1,
                Enum.at(prev_row, j) + cost
              ])

            row ++ [val]
          end)

        {current_row, i + 1}
      end)

    List.last(dist)
  end

  @descriptors ~w(
    large small medium extra fresh frozen dried organic
    raw cooked ripe unripe whole boneless skinless
  )

  defp strip_descriptors(name) do
    words = String.split(name, " ")

    stripped =
      words
      |> Enum.reject(&(&1 in @descriptors))
      |> Enum.join(" ")

    if String.trim(stripped) == "", do: name, else: stripped
  end

  defp singularize(word) do
    cond do
      String.ends_with?(word, "ies") ->
        String.slice(word, 0..-4//1) <> "y"

      String.ends_with?(word, "ves") ->
        String.slice(word, 0..-4//1) <> "f"

      String.ends_with?(word, "es") and
          String.ends_with?(word, ["shes", "ches", "xes", "zes", "sses"]) ->
        String.slice(word, 0..-3//1)

      String.ends_with?(word, "s") and not String.ends_with?(word, "ss") ->
        String.slice(word, 0..-2//1)

      true ->
        word
    end
  end
end
