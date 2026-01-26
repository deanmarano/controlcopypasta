defmodule Controlcopypasta.Repo.Migrations.AddSalmonFilletDensity do
  use Ecto.Migration

  def up do
    # Add count-based density for salmon fillet (typical fillet is ~170g / 6oz)
    execute """
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, volume_unit, grams_per_unit, source, notes, inserted_at, updated_at)
    SELECT
      gen_random_uuid(),
      '2f9b7331-5ae1-4bdb-b5f6-3772d39086c5',
      'each',
      170,
      'standard estimate',
      'Typical 5-6oz salmon fillet',
      NOW(),
      NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities
      WHERE canonical_ingredient_id = '2f9b7331-5ae1-4bdb-b5f6-3772d39086c5'
      AND volume_unit = 'each'
    )
    """
  end

  def down do
    execute """
    DELETE FROM ingredient_densities
    WHERE canonical_ingredient_id = '2f9b7331-5ae1-4bdb-b5f6-3772d39086c5'
    AND volume_unit = 'each'
    """
  end
end
