defmodule Controlcopypasta.Ingredients.Matching.Matcher do
  @moduledoc """
  Ingredient matching with cascading strategies.

  Attempts to match an ingredient name to a canonical ingredient using
  multiple strategies in order of confidence:

  1. Exact match (1.0)
  2. Singularized exact match (0.98)
  3. Stripped modifiers match (0.95)
  4. Singularized stripped match (0.93)
  5. Progressively shorter matches (0.9)
  6. Single word match (0.8)
  7. Fuzzy prefix match (0.7)
  """

  alias Controlcopypasta.Ingredients.Parsing.Singularizer

  @doc """
  Matches an ingredient name to a canonical ingredient.

  Returns a map with:
  - `name`: Original input name
  - `canonical_name`: Matched canonical name (or nil)
  - `canonical_id`: Matched canonical ID (or nil)
  - `confidence`: Match confidence (0.0-1.0)

  ## Examples

      iex> lookup = %{"olive oil" => {"olive oil", "id123"}}
      iex> Matcher.match("olive oil", lookup)
      %{name: "olive oil", canonical_name: "olive oil", canonical_id: "id123", confidence: 1.0}

      iex> Matcher.match("fresh basil", %{"basil" => {"basil", "id456"}})
      %{name: "fresh basil", canonical_name: "basil", canonical_id: "id456", confidence: 0.95}
  """
  def match(name, lookup) do
    normalized = String.downcase(name) |> String.trim()

    case find_canonical_match(normalized, lookup) do
      {canonical_name, canonical_id, confidence} ->
        %{
          name: name,
          canonical_name: canonical_name,
          canonical_id: canonical_id,
          confidence: confidence
        }

      nil ->
        %{
          name: name,
          canonical_name: nil,
          canonical_id: nil,
          confidence: 0.5
        }
    end
  end

  @doc """
  Find canonical match using various strategies.

  Returns `{canonical_name, canonical_id, confidence}` or `nil`.
  """
  def find_canonical_match(name, lookup) do
    # Strategy 1: Exact match
    case Map.get(lookup, name) do
      {canonical_name, id} -> {canonical_name, id, 1.0}
      nil ->
        # Strategy 1b: Try singularized form
        singular = singularize_phrase(name)
        case if(singular != name, do: Map.get(lookup, singular)) do
          {canonical_name, id} -> {canonical_name, id, 0.98}
          _ -> try_partial_match(name, lookup)
        end
    end
  end

  # Leading modifiers to strip (adjectives that describe ingredient state/size)
  @leading_modifiers ~w(fresh dried frozen canned raw cooked large small medium
                        extra-large whole ground light dark unsalted salted organic
                        ripe unripe hot cold warm thin thick fine coarse)

  # Try partial matching strategies (strip modifiers, shorten)
  defp try_partial_match(name, lookup) do
    words = String.split(name, " ")

    # Strategy 2: Remove leading adjectives (fresh, large, etc.)
    stripped = strip_leading_modifiers(words)
    case Map.get(lookup, stripped) do
      {canonical_name, id} -> {canonical_name, id, 0.95}
      nil ->
        # Strategy 2b: Try singularized stripped form
        singular_stripped = singularize_phrase(stripped)
        case if(singular_stripped != stripped, do: Map.get(lookup, singular_stripped)) do
          {canonical_name, id} -> {canonical_name, id, 0.93}
          _ -> try_shorter_matches(words, lookup)
        end
    end
  end

  defp strip_leading_modifiers(words) do
    words
    |> Enum.drop_while(&(String.downcase(&1) in @leading_modifiers))
    |> Enum.join(" ")
  end

  # Try progressively shorter versions
  defp try_shorter_matches(words, lookup) when length(words) > 1 do
    # Try removing first word
    shorter_front = words |> tl() |> Enum.join(" ")
    case Map.get(lookup, shorter_front) do
      {canonical_name, id} -> {canonical_name, id, 0.9}
      nil ->
        # Try removing last word
        shorter_back = words |> Enum.take(length(words) - 1) |> Enum.join(" ")
        case Map.get(lookup, shorter_back) do
          {canonical_name, id} -> {canonical_name, id, 0.9}
          nil -> try_shorter_matches(tl(words), lookup)
        end
    end
  end

  defp try_shorter_matches([single_word], lookup) do
    case Map.get(lookup, single_word) do
      {canonical_name, id} -> {canonical_name, id, 0.8}
      nil -> try_fuzzy_match(single_word, lookup)
    end
  end

  defp try_shorter_matches([], _lookup), do: nil

  # Conservative fuzzy matching
  defp try_fuzzy_match(name, lookup) do
    # Only try prefix matching for longer names
    if String.length(name) >= 4 do
      # Find canonical that starts with this name or vice versa
      match = Enum.find(lookup, fn {key, _} ->
        String.starts_with?(key, name <> " ") or
        String.starts_with?(name, key <> " ")
      end)

      case match do
        {_key, {canonical_name, id}} -> {canonical_name, id, 0.7}
        nil -> nil
      end
    else
      nil
    end
  end

  @doc """
  Singularize a multi-word phrase by singularizing the last word.

  ## Examples

      iex> Matcher.singularize_phrase("red peppers")
      "red pepper"

      iex> Matcher.singularize_phrase("cherry tomatoes")
      "cherry tomato"
  """
  def singularize_phrase(phrase) do
    words = String.split(phrase, " ")

    case words do
      [] -> phrase
      [single] -> Singularizer.singularize(single)
      multiple ->
        last = List.last(multiple)
        rest = Enum.take(multiple, length(multiple) - 1)
        singular_last = Singularizer.singularize(last)
        Enum.join(rest ++ [singular_last], " ")
    end
  end
end
