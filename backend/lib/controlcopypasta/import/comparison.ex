defmodule Controlcopypasta.Import.Comparison do
  @moduledoc """
  Compares parsed recipe data against Copy Me That reference data.
  Used to identify parser improvements needed.
  """

  @doc """
  Compares parsed recipe data against CMT reference data.
  Returns a map of differences for each field.

  ## Example

      iex> compare(parsed_data, cmt_data)
      %{
        title: :match,
        ingredients: {:mismatch, %{parsed: [...], expected: [...], missing: [...], extra: [...]}},
        instructions: :match,
        ...
      }
  """
  def compare(parsed, cmt) do
    %{
      title: compare_string(parsed[:title], cmt["name"]),
      description: compare_string(parsed[:description], cmt["description"]),
      image_url: compare_string(parsed[:image_url], cmt["image"]),
      ingredients: compare_ingredients(parsed[:ingredients] || [], cmt["ingredients"] || []),
      instructions: compare_instructions(parsed[:instructions] || [], cmt["instructions"]),
      prep_time_minutes: compare_time(parsed[:prep_time_minutes], cmt["prepTime"]),
      cook_time_minutes: compare_time(parsed[:cook_time_minutes], cmt["cookTime"]),
      total_time_minutes: compare_time(parsed[:total_time_minutes], cmt["totalTime"]),
      servings: compare_string(parsed[:servings], cmt["yield"])
    }
  end

  @doc """
  Returns a summary of the comparison - how many fields match vs mismatch.
  """
  def summary(comparison) do
    {matches, mismatches} =
      comparison
      |> Enum.reduce({0, 0}, fn
        {_field, :match}, {m, mm} -> {m + 1, mm}
        {_field, :both_nil}, {m, mm} -> {m + 1, mm}
        {_field, {:mismatch, _}}, {m, mm} -> {m, mm + 1}
      end)

    %{
      matches: matches,
      mismatches: mismatches,
      total: matches + mismatches,
      score: if(matches + mismatches > 0, do: matches / (matches + mismatches), else: 1.0)
    }
  end

  @doc """
  Returns only the mismatched fields from a comparison.
  """
  def mismatches(comparison) do
    comparison
    |> Enum.filter(fn
      {_field, {:mismatch, _}} -> true
      _ -> false
    end)
    |> Map.new()
  end

  # String comparison - handles nil, whitespace normalization
  defp compare_string(nil, nil), do: :both_nil
  defp compare_string(nil, ""), do: :both_nil
  defp compare_string("", nil), do: :both_nil
  defp compare_string(nil, expected), do: {:mismatch, %{parsed: nil, expected: expected}}
  defp compare_string(parsed, nil), do: {:mismatch, %{parsed: parsed, expected: nil}}

  defp compare_string(parsed, expected) when is_binary(parsed) and is_binary(expected) do
    normalized_parsed = normalize_string(parsed)
    normalized_expected = normalize_string(expected)

    if normalized_parsed == normalized_expected do
      :match
    else
      # Check for partial match (one contains the other)
      similarity = string_similarity(normalized_parsed, normalized_expected)

      {:mismatch,
       %{
         parsed: parsed,
         expected: expected,
         similarity: similarity
       }}
    end
  end

  # Ingredient comparison
  defp compare_ingredients(parsed, expected) when is_list(parsed) do
    parsed_texts = Enum.map(parsed, &normalize_ingredient/1)
    expected_texts = normalize_expected_ingredients(expected)

    missing = expected_texts -- parsed_texts
    extra = parsed_texts -- expected_texts
    matched = expected_texts -- missing

    if missing == [] and extra == [] do
      :match
    else
      {:mismatch,
       %{
         parsed: parsed_texts,
         expected: expected_texts,
         matched: matched,
         missing: missing,
         extra: extra,
         match_rate: length(matched) / max(length(expected_texts), 1)
       }}
    end
  end

  defp normalize_ingredient(%{"text" => text}), do: normalize_string(text)
  defp normalize_ingredient(text) when is_binary(text), do: normalize_string(text)
  defp normalize_ingredient(_), do: ""

  defp normalize_expected_ingredients(ingredients) when is_list(ingredients) do
    Enum.map(ingredients, fn
      text when is_binary(text) -> normalize_string(text)
      %{"text" => text} -> normalize_string(text)
      _ -> ""
    end)
  end

  defp normalize_expected_ingredients(ingredients) when is_binary(ingredients) do
    ingredients
    |> String.split("\n")
    |> Enum.map(&normalize_string/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_expected_ingredients(_), do: []

  # Instruction comparison
  defp compare_instructions(parsed, expected) when is_list(parsed) do
    parsed_texts = Enum.map(parsed, &normalize_instruction/1)
    expected_texts = normalize_expected_instructions(expected)

    # Compare normalized versions (both lowercased)
    parsed_normalized = Enum.map(parsed_texts, &String.downcase/1)
    expected_normalized = Enum.map(expected_texts, &String.downcase/1)

    if parsed_normalized == expected_normalized do
      :match
    else
      # Calculate similarity
      matched_count =
        Enum.zip(parsed_normalized, expected_normalized)
        |> Enum.count(fn {p, e} -> p == e end)

      {:mismatch,
       %{
         parsed: parsed_texts,
         expected: expected_texts,
         parsed_count: length(parsed_texts),
         expected_count: length(expected_texts),
         matched_count: matched_count
       }}
    end
  end

  defp compare_instructions(parsed, expected) do
    {:mismatch, %{parsed: parsed, expected: expected}}
  end

  defp normalize_instruction(%{"text" => text}), do: normalize_string(text)
  defp normalize_instruction(text) when is_binary(text), do: normalize_string(text)
  defp normalize_instruction(_), do: ""

  defp normalize_expected_instructions(nil), do: []

  defp normalize_expected_instructions(instructions) when is_binary(instructions) do
    instructions
    |> String.split(~r/\n+/)
    |> Enum.map(&String.trim/1)
    |> Enum.map(&remove_step_prefix/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp normalize_expected_instructions(instructions) when is_list(instructions) do
    Enum.map(instructions, fn
      %{"text" => text} -> normalize_string(text)
      text when is_binary(text) -> normalize_string(text)
      _ -> ""
    end)
  end

  defp remove_step_prefix(text) do
    text
    |> String.replace(~r/^(Step\s*)?\d+[\.\)]\s*/i, "")
    |> String.trim()
  end

  # Time comparison
  defp compare_time(nil, nil), do: :both_nil
  defp compare_time(parsed, nil), do: {:mismatch, %{parsed: parsed, expected: nil}}
  defp compare_time(nil, expected), do: {:mismatch, %{parsed: nil, expected: expected}}

  defp compare_time(parsed, expected) when is_integer(parsed) and is_binary(expected) do
    expected_minutes = parse_time_string(expected)

    if parsed == expected_minutes do
      :match
    else
      {:mismatch, %{parsed: parsed, expected: expected, expected_minutes: expected_minutes}}
    end
  end

  defp compare_time(parsed, expected) when is_integer(parsed) and is_integer(expected) do
    if parsed == expected, do: :match, else: {:mismatch, %{parsed: parsed, expected: expected}}
  end

  defp parse_time_string(time) when is_binary(time) do
    cond do
      String.match?(time, ~r/(\d+)\s*h.*?(\d+)\s*m/i) ->
        case Regex.run(~r/(\d+)\s*h.*?(\d+)\s*m/i, time) do
          [_, hours, minutes | _] ->
            String.to_integer(hours) * 60 + String.to_integer(minutes)

          _ ->
            nil
        end

      String.match?(time, ~r/(\d+)\s*h(our|r)?/i) ->
        case Regex.run(~r/(\d+)\s*h(our|r)?/i, time) do
          [_, hours | _] -> String.to_integer(hours) * 60
          _ -> nil
        end

      String.match?(time, ~r/(\d+)\s*m(in)?/i) ->
        case Regex.run(~r/(\d+)\s*m(in)?/i, time) do
          [_, minutes | _] -> String.to_integer(minutes)
          _ -> nil
        end

      true ->
        nil
    end
  end

  defp parse_time_string(_), do: nil

  # Utility functions
  defp normalize_string(nil), do: ""

  defp normalize_string(text) when is_binary(text) do
    text
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.downcase()
  end

  defp string_similarity(a, b) when is_binary(a) and is_binary(b) do
    # Simple Jaccard similarity on words
    words_a = String.split(a, ~r/\s+/) |> MapSet.new()
    words_b = String.split(b, ~r/\s+/) |> MapSet.new()

    intersection = MapSet.intersection(words_a, words_b) |> MapSet.size()
    union = MapSet.union(words_a, words_b) |> MapSet.size()

    if union > 0, do: intersection / union, else: 0.0
  end
end
