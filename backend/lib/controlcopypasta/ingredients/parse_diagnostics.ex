defmodule Controlcopypasta.Ingredients.ParseDiagnostics do
  @moduledoc """
  Captures diagnostic information during ingredient parsing.

  When diagnostics are enabled, this struct captures details about:
  - How the ingredient was tokenized
  - Which parser handled it (standard or sub-parser)
  - What canonical matches were considered
  - Why a particular match was chosen
  - Timing information

  This is useful for debugging parsing issues and understanding
  why certain ingredients are matched (or not matched) the way they are.
  """

  defstruct [
    # List of Token structs
    :tokens,
    # Formatted: "[1:qty] [cup:unit] [flour:word]"
    :token_string,
    # :standard | :garlic | :citrus | :egg
    :parser_used,
    # List of top match candidates considered
    :match_candidates,
    # The chosen match with reason
    :selected_match,
    # How the match was found (exact, singularized, partial, etc.)
    :match_strategy,
    # Any parsing anomalies detected
    :warnings,
    # Microseconds to parse
    :parse_time_us
  ]

  @type match_candidate :: %{
          name: String.t(),
          canonical_name: String.t() | nil,
          confidence: float(),
          strategy: atom()
        }

  @type t :: %__MODULE__{
          tokens: [Controlcopypasta.Ingredients.Tokenizer.Token.t()],
          token_string: String.t(),
          parser_used: atom(),
          match_candidates: [match_candidate()],
          selected_match: map() | nil,
          match_strategy: atom() | nil,
          warnings: [String.t()],
          parse_time_us: non_neg_integer()
        }

  @doc """
  Converts diagnostics to a map suitable for JSONB storage.

  The output is prefixed with underscore to indicate it's internal/debug data.
  """
  def to_map(%__MODULE__{} = diag) do
    %{
      "tokens" => diag.token_string,
      "parser" => Atom.to_string(diag.parser_used),
      "match_strategy" => if(diag.match_strategy, do: Atom.to_string(diag.match_strategy)),
      "alternatives" => format_candidates(diag.match_candidates),
      "warnings" => diag.warnings,
      "parse_time_us" => diag.parse_time_us
    }
  end

  defp format_candidates(nil), do: []

  defp format_candidates(candidates) do
    candidates
    |> Enum.take(3)
    |> Enum.map(fn c -> c.canonical_name || c.name end)
  end

  @doc """
  Detects potential parsing issues and returns warning messages.
  """
  def detect_warnings(tokens, result) do
    warnings = []

    # Warning: No canonical match found
    warnings =
      if result.primary_ingredient && is_nil(result.primary_ingredient.canonical_id) do
        ["No canonical match found" | warnings]
      else
        warnings
      end

    # Warning: Low confidence match
    warnings =
      if result.primary_ingredient && result.primary_ingredient.confidence < 0.8 do
        [
          "Low confidence match (#{Float.round(result.primary_ingredient.confidence, 2)})"
          | warnings
        ]
      else
        warnings
      end

    # Warning: Multiple word tokens but no match
    word_count = Enum.count(tokens, &(&1.label == :word))

    warnings =
      if word_count > 2 && is_nil(result.primary_ingredient.canonical_id) do
        ["Complex ingredient phrase (#{word_count} words) with no match" | warnings]
      else
        warnings
      end

    # Warning: Has alternatives (or pattern)
    warnings =
      if result.is_alternative do
        ["Has alternatives (or pattern detected)" | warnings]
      else
        warnings
      end

    Enum.reverse(warnings)
  end
end
