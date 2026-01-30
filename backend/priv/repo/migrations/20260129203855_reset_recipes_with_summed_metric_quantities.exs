defmodule Controlcopypasta.Repo.Migrations.ResetRecipesWithSummedMetricQuantities do
  use Ecto.Migration

  @moduledoc """
  Resets ingredients_parsed_at for recipes affected by the quantity summing bug.

  The bug caused quantities inside parentheses (metric conversions like "907 g")
  to be summed with the primary quantity, e.g.:
    "2 pounds (907 g)" -> quantity: 909 (instead of 2)

  This migration identifies affected recipes by looking for ingredients where:
  1. The quantity value is > 100
  2. The text contains parentheses (metric conversion pattern)

  After running this migration, trigger re-parsing with:

      # In IEx on production:
      %{"force" => true}
      |> Controlcopypasta.Workers.IngredientParser.new()
      |> Oban.insert()

  Or via the admin API endpoint.
  """

  def up do
    # Reset ingredients_parsed_at for recipes that have ingredients with
    # suspiciously high quantities (> 100) AND contain parentheses in the text
    # (indicating metric conversions that were incorrectly summed)
    execute """
    UPDATE recipes
    SET ingredients_parsed_at = NULL
    WHERE ingredients_parsed_at IS NOT NULL
    AND EXISTS (
      SELECT 1
      FROM jsonb_array_elements(ingredients) AS elem
      WHERE (elem->'quantity'->>'value')::numeric > 100
      AND elem->>'text' ~ '\\([^)]*[0-9]+[^)]*\\)'
    )
    """
  end

  def down do
    # No-op: re-parsing will set the timestamp again
    :ok
  end
end
