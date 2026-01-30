defmodule Controlcopypasta.Repo.Migrations.FixAlmondMealSeparateFromFlour do
  use Ecto.Migration

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    # Remove "almond meal" from almond flour's aliases - they are different products
    # Almond flour = blanched almonds, finely ground
    # Almond meal = whole almonds with skins, coarser texture
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_remove(aliases, 'almond meal')
    WHERE name = 'almond flour'
    """

    # Create separate almond meal canonical
    execute """
    INSERT INTO canonical_ingredients (id, name, display_name, category, aliases, is_allergen, allergen_groups, dietary_flags, inserted_at, updated_at)
    VALUES (
      gen_random_uuid(),
      'almond meal',
      'Almond Meal',
      'baking',
      ARRAY['ground almonds with skins']::varchar[],
      true,
      ARRAY['tree_nuts']::varchar[],
      ARRAY['vegan', 'vegetarian', 'gluten_free', 'dairy_free']::varchar[],
      '#{now}',
      '#{now}'
    )
    ON CONFLICT (name) DO NOTHING
    """
  end

  def down do
    # Remove almond meal canonical
    execute "DELETE FROM canonical_ingredients WHERE name = 'almond meal'"

    # Add "almond meal" back to almond flour aliases
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'almond meal')
    WHERE name = 'almond flour'
    """
  end
end
