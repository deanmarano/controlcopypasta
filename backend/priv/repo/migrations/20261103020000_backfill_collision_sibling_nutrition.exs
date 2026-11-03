defmodule Controlcopypasta.Repo.Migrations.BackfillCollisionSiblingNutrition do
  use Ecto.Migration

  @moduledoc """
  Backfills nutrition and density for canonical ingredients that an ambiguous
  alias used to resolve away from.

  158 keys in the catalog are claimed more than once, and the lookup resolved
  them by last-writer-wins over an unordered query. "cremini mushrooms" is an
  alias of both `crimini mushroom` and `mushroom`, so it landed on whichever
  Postgres happened to return last -- which is why the nutrition completeness
  test failed intermittently on "4 cremini mushrooms, halved" for months: only
  `mushroom` carried a count density.

  Now that precedence is deterministic, these ingredients win their keys
  consistently, and the ones missing data need it filled in.

  The values are copied from a sibling that already has them rather than
  estimated, so nothing is invented here:

      crimini mushroom       <- mushroom
      tamari                 <- soy sauce
      five-spice powder      <- chinese five spice
      green chile            <- serrano chile
      vanilla protein powder <- protein powder

  Soy sauce and tamari also get a `cup` density derived from their own `tbsp`
  value (16 tbsp to the cup); previously neither could convert a cup measure.

  Idempotent: a row is only inserted where the target has none.
  """

  @pairs [
    {"crimini mushroom", "mushroom"},
    {"tamari", "soy sauce"},
    {"five-spice powder", "chinese five spice"},
    {"green chile", "serrano chile"},
    {"vanilla protein powder", "protein powder"}
  ]

  def up do
    for {target, donor} <- @pairs do
      copy_nutrition(target, donor)
      copy_densities(target, donor)
    end

    derive_cup_from_tbsp("soy sauce")
    derive_cup_from_tbsp("tamari")
  end

  # Purely additive; removing the rows again would restore an intermittent
  # failure rather than a meaningful earlier state.
  def down, do: :ok

  defp copy_nutrition(target, donor) do
    repo().query!(
      """
      INSERT INTO ingredient_nutrition
        (id, canonical_ingredient_id, source, serving_size_value, serving_size_unit,
         calories, protein_g, fat_total_g, fat_saturated_g, carbohydrates_g, fiber_g,
         sugar_g, sodium_mg, cholesterol_mg, potassium_mg, calcium_mg, iron_mg,
         is_primary, confidence, inserted_at, updated_at)
      SELECT gen_random_uuid(), tgt.id, n.source, n.serving_size_value, n.serving_size_unit,
             n.calories, n.protein_g, n.fat_total_g, n.fat_saturated_g, n.carbohydrates_g,
             n.fiber_g, n.sugar_g, n.sodium_mg, n.cholesterol_mg, n.potassium_mg,
             n.calcium_mg, n.iron_mg, true, n.confidence, NOW(), NOW()
      FROM canonical_ingredients tgt
      JOIN canonical_ingredients src ON src.name = $2
      JOIN ingredient_nutrition n ON n.canonical_ingredient_id = src.id AND n.is_primary
      WHERE tgt.name = $1
        AND NOT EXISTS (
          SELECT 1 FROM ingredient_nutrition e WHERE e.canonical_ingredient_id = tgt.id
        )
      """,
      [target, donor]
    )
  end

  defp copy_densities(target, donor) do
    repo().query!(
      """
      INSERT INTO ingredient_densities
        (id, canonical_ingredient_id, volume_unit, grams_per_unit, preparation,
         source, inserted_at, updated_at)
      SELECT DISTINCT ON (d.volume_unit)
             gen_random_uuid(), tgt.id, d.volume_unit, d.grams_per_unit, d.preparation,
             'manual', NOW(), NOW()
      FROM canonical_ingredients tgt
      JOIN canonical_ingredients src ON src.name = $2
      JOIN ingredient_densities d ON d.canonical_ingredient_id = src.id
      WHERE tgt.name = $1
        AND NOT EXISTS (
          SELECT 1 FROM ingredient_densities e
          WHERE e.canonical_ingredient_id = tgt.id AND e.volume_unit = d.volume_unit
        )
      ORDER BY d.volume_unit, d.grams_per_unit
      """,
      [target, donor]
    )
  end

  defp derive_cup_from_tbsp(name) do
    repo().query!(
      """
      INSERT INTO ingredient_densities
        (id, canonical_ingredient_id, volume_unit, grams_per_unit, preparation,
         source, inserted_at, updated_at)
      SELECT gen_random_uuid(), c.id, 'cup', d.grams_per_unit * 16, NULL,
             'manual', NOW(), NOW()
      FROM canonical_ingredients c
      JOIN ingredient_densities d
        ON d.canonical_ingredient_id = c.id AND d.volume_unit = 'tbsp'
      WHERE c.name = $1
        AND NOT EXISTS (
          SELECT 1 FROM ingredient_densities e
          WHERE e.canonical_ingredient_id = c.id AND e.volume_unit = 'cup'
        )
      """,
      [name]
    )
  end
end
