defmodule Controlcopypasta.Repo.Migrations.BackfillCaloriesFromMacros do
  use Ecto.Migration

  def up do
    # Backfill calories from macros using standard conversion:
    # Protein: 4 kcal/g, Carbohydrates: 4 kcal/g, Fat: 9 kcal/g
    execute """
    UPDATE ingredient_nutrition
    SET calories = ROUND(
      COALESCE(protein_g, 0) * 4 +
      COALESCE(carbohydrates_g, 0) * 4 +
      COALESCE(fat_total_g, 0) * 9
    )
    WHERE calories IS NULL
      AND (protein_g IS NOT NULL OR carbohydrates_g IS NOT NULL OR fat_total_g IS NOT NULL)
    """
  end

  def down do
    # No rollback - we can't distinguish calculated from original values
    :ok
  end
end
