defmodule Controlcopypasta.Repo.Migrations.BackfillFatTotalFromBreakdown do
  use Ecto.Migration

  def up do
    # First, backfill fat_total_g from fat breakdown components
    # fat_total = saturated + polyunsaturated + monounsaturated + trans
    execute """
    UPDATE ingredient_nutrition
    SET fat_total_g = ROUND(
      COALESCE(fat_saturated_g, 0) +
      COALESCE(fat_polyunsaturated_g, 0) +
      COALESCE(fat_monounsaturated_g, 0) +
      COALESCE(fat_trans_g, 0),
      2
    )
    WHERE fat_total_g IS NULL
      AND (fat_saturated_g IS NOT NULL OR fat_polyunsaturated_g IS NOT NULL OR fat_monounsaturated_g IS NOT NULL)
    """

    # Then recalculate calories for records that now have fat_total_g
    execute """
    UPDATE ingredient_nutrition
    SET calories = ROUND(
      COALESCE(protein_g, 0) * 4 +
      COALESCE(carbohydrates_g, 0) * 4 +
      COALESCE(fat_total_g, 0) * 9
    )
    WHERE calories IS NULL
      AND fat_total_g IS NOT NULL
    """
  end

  def down do
    # No rollback - we can't distinguish calculated from original values
    :ok
  end
end
