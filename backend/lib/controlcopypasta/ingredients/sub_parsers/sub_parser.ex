defmodule Controlcopypasta.Ingredients.SubParsers.SubParser do
  @moduledoc """
  Behaviour for ingredient-specific sub-parsers.

  Sub-parsers intercept before the standard TokenParser flow to handle
  patterns that the generic parser mishandles (e.g., garlic cloves,
  citrus juice/zest, egg compounds).

  Each sub-parser implements:
  - `match?/1` — cheap token scan to decide if this parser applies
  - `parse/3` — full parse returning `{:ok, ParsedIngredient}` or `:skip`
  """

  alias Controlcopypasta.Ingredients.Tokenizer.Token
  alias Controlcopypasta.Ingredients.TokenParser.ParsedIngredient

  @callback match?(tokens :: [Token.t()]) :: boolean()
  @callback parse(tokens :: [Token.t()], original :: String.t(), lookup :: map()) ::
              {:ok, ParsedIngredient.t()} | :skip
end
