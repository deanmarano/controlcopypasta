defmodule Controlcopypasta.Ingredients.SubParsers.RecipeReference do
  @moduledoc """
  Sub-parser for ingredients that reference other recipes.

  Detects patterns like:
  - "1 cup pesto (see recipe below)"
  - "homemade mayo, recipe follows"
  - "use the spice blend (recipe above)"
  - "1 tbsp garam masala (see notes)"
  - "chicken stock, homemade or store-bought"

  Extracts the recipe reference information and stores it in the
  `recipe_reference` field of ParsedIngredient.
  """

  @behaviour Controlcopypasta.Ingredients.SubParsers.SubParser

  alias Controlcopypasta.Ingredients.TokenParser
  alias Controlcopypasta.Ingredients.TokenParser.ParsedIngredient

  # Reference indicator words
  @below_indicators ~w(below follows following)
  @above_indicators ~w(above)
  @notes_indicators ~w(notes note)
  @optional_indicators ~w(store-bought storebought purchased)

  # Match patterns
  @recipe_words ~w(recipe)
  @see_words ~w(see)
  @homemade_words ~w(homemade home-made)

  @impl true
  def match?(tokens) do
    texts = tokens |> Enum.map(&String.downcase(&1.text))
    combined = Enum.join(texts, " ")

    has_recipe_reference?(combined) or has_notes_reference?(combined) or
      has_optional_pattern?(combined)
  end

  defp has_recipe_reference?(text) do
    # "recipe below", "recipe follows", "recipe above", "see recipe"
    String.contains?(text, "recipe") and
      (has_direction_indicator?(text) or String.contains?(text, "see"))
  end

  defp has_notes_reference?(text) do
    # "see notes", "in notes"
    Enum.any?(@notes_indicators, &String.contains?(text, &1)) and
      (String.contains?(text, "see") or String.contains?(text, "in "))
  end

  defp has_optional_pattern?(text) do
    # "homemade or store-bought"
    Enum.any?(@homemade_words, &String.contains?(text, &1)) and
      String.contains?(text, " or ") and
      Enum.any?(@optional_indicators, &String.contains?(text, &1))
  end

  defp has_direction_indicator?(text) do
    Enum.any?(@below_indicators ++ @above_indicators, &String.contains?(text, &1))
  end

  @impl true
  def parse(tokens, original, lookup) do
    texts = tokens |> Enum.map(&String.downcase(&1.text))
    combined = Enum.join(texts, " ")

    reference = detect_reference(combined)

    if reference do
      # Parse the base ingredient (everything before the reference)
      base_tokens = filter_reference_tokens(tokens)

      # Use standard parser for the ingredient part
      case parse_base_ingredient(base_tokens, original, lookup) do
        {:ok, parsed} ->
          {:ok, %{parsed | recipe_reference: reference}}

        :skip ->
          # Still return with reference even if base parsing fails
          {:ok,
           %ParsedIngredient{
             original: original,
             recipe_reference: reference
           }}
      end
    else
      :skip
    end
  end

  defp detect_reference(text) do
    cond do
      # "recipe below" or "see recipe below" or "recipe follows"
      match_below?(text) ->
        %{
          type: :below,
          text: extract_reference_text(text, @below_indicators),
          name: extract_ingredient_name(text),
          is_optional: false
        }

      # "recipe above" or "see recipe above"
      match_above?(text) ->
        %{
          type: :above,
          text: extract_reference_text(text, @above_indicators),
          name: extract_ingredient_name(text),
          is_optional: false
        }

      # "see notes" or "in notes"
      match_notes?(text) ->
        %{
          type: :notes,
          text: extract_notes_text(text),
          name: extract_ingredient_name(text),
          is_optional: false
        }

      # "homemade or store-bought"
      match_optional?(text) ->
        %{
          type: :below,
          text: "homemade or store-bought",
          name: extract_ingredient_name(text),
          is_optional: true
        }

      true ->
        nil
    end
  end

  defp match_below?(text) do
    (String.contains?(text, "recipe") and
       Enum.any?(@below_indicators, &String.contains?(text, &1))) or
      (String.contains?(text, "see recipe") and not match_above?(text))
  end

  defp match_above?(text) do
    String.contains?(text, "recipe") and
      Enum.any?(@above_indicators, &String.contains?(text, &1))
  end

  defp match_notes?(text) do
    (String.contains?(text, "see") or String.contains?(text, "in ")) and
      Enum.any?(@notes_indicators, &String.contains?(text, &1))
  end

  defp match_optional?(text) do
    Enum.any?(@homemade_words, &String.contains?(text, &1)) and
      String.contains?(text, " or ") and
      Enum.any?(@optional_indicators, &String.contains?(text, &1))
  end

  defp extract_reference_text(text, indicators) do
    # Find the reference phrase like "see recipe below"
    pattern = ~r/(see\s+)?recipe\s+(#{Enum.join(indicators, "|")})/i

    case Regex.run(pattern, text) do
      [match | _] -> String.trim(match)
      nil -> nil
    end
  end

  defp extract_notes_text(text) do
    pattern = ~r/(see\s+|in\s+)(the\s+)?notes?/i

    case Regex.run(pattern, text) do
      [match | _] -> String.trim(match)
      nil -> "see notes"
    end
  end

  defp extract_ingredient_name(text) do
    # Remove common reference phrases to get the ingredient name
    text
    # Remove parentheticals
    |> String.replace(~r/\s*\(.*?\)\s*/, " ")
    |> String.replace(~r/,?\s*(see\s+)?(recipe\s+)?(below|above|follows|following)\s*/i, " ")
    |> String.replace(~r/,?\s*(see\s+)?(the\s+)?notes?\s*/i, " ")
    |> String.replace(~r/,?\s*homemade\s+or\s+store-?bought\s*/i, " ")
    |> String.replace(~r/,?\s*recipe\s+follows\s*/i, " ")
    # Remove quantities
    |> String.replace(~r/\d+\s*(cups?|tbsps?|tsps?|oz|lbs?)\s*/i, " ")
    |> String.trim()
    |> String.trim(",")
    |> String.trim()
    |> case do
      "" -> nil
      name -> name
    end
  end

  defp filter_reference_tokens(tokens) do
    # Remove tokens that are part of the reference phrase
    reference_words =
      @below_indicators ++
        @above_indicators ++
        @notes_indicators ++
        @recipe_words ++ @see_words ++ @optional_indicators ++ ["or", "(", ")"]

    Enum.reject(tokens, fn token ->
      String.downcase(token.text) in reference_words or
        String.starts_with?(token.text, "(") or
        String.ends_with?(token.text, ")")
    end)
  end

  defp parse_base_ingredient(tokens, _original, lookup) when length(tokens) > 0 do
    # Reconstruct text and parse with standard parser
    text = tokens |> Enum.map(& &1.text) |> Enum.join(" ")

    case TokenParser.parse_standard(tokens, text, lookup) do
      %ParsedIngredient{} = parsed -> {:ok, parsed}
      _ -> :skip
    end
  rescue
    _ -> :skip
  end

  defp parse_base_ingredient(_, _, _), do: :skip
end
