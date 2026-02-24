defmodule Controlcopypasta.Repo.Migrations.CleanupDuplicateIngredients do
  use Ecto.Migration

  @moduledoc """
  Cleans up duplicate canonical ingredients by:
  1. Adding the duplicate name as an alias to the canonical one
  2. Deleting the duplicate entry

  Duplicates found:
  - za'atar / zaatar
  - andouille sausage / andouille sausages
  - poppy seed / poppy seeds
  - sardine / sardines
  """

  def up do
    # For each duplicate pair: add alias to keeper, delete duplicate

    # 1. za'atar (keep) / zaatar (delete) - keep the one with apostrophe
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'zaatar')
    WHERE name = 'za''atar'
    AND NOT ('zaatar' = ANY(aliases))
    """

    execute "DELETE FROM canonical_ingredients WHERE name = 'zaatar'"

    # 2. andouille sausage (keep singular) / andouille sausages (delete)
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'andouille sausages')
    WHERE name = 'andouille sausage'
    AND NOT ('andouille sausages' = ANY(aliases))
    """

    execute "DELETE FROM canonical_ingredients WHERE name = 'andouille sausages'"

    # 3. poppy seeds (keep plural) / poppy seed (delete)
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'poppy seed')
    WHERE name = 'poppy seeds'
    AND NOT ('poppy seed' = ANY(aliases))
    """

    execute "DELETE FROM canonical_ingredients WHERE name = 'poppy seed'"

    # 4. sardines (keep plural) / sardine (delete)
    execute """
    UPDATE canonical_ingredients
    SET aliases = array_append(aliases, 'sardine')
    WHERE name = 'sardines'
    AND NOT ('sardine' = ANY(aliases))
    """

    execute "DELETE FROM canonical_ingredients WHERE name = 'sardine'"
  end

  def down do
    # Recreate the deleted duplicates (without full data - just names)
    # This is a lossy rollback but prevents migration failures

    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    execute """
    INSERT INTO canonical_ingredients (id, name, display_name, aliases, is_allergen, allergen_groups, dietary_flags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), 'zaatar', 'Zaatar', ARRAY[]::varchar[], false, ARRAY[]::varchar[], ARRAY[]::varchar[], '#{now}', '#{now}')
    ON CONFLICT (name) DO NOTHING
    """

    execute """
    INSERT INTO canonical_ingredients (id, name, display_name, aliases, is_allergen, allergen_groups, dietary_flags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), 'andouille sausages', 'Andouille Sausages', ARRAY[]::varchar[], false, ARRAY[]::varchar[], ARRAY[]::varchar[], '#{now}', '#{now}')
    ON CONFLICT (name) DO NOTHING
    """

    execute """
    INSERT INTO canonical_ingredients (id, name, display_name, aliases, is_allergen, allergen_groups, dietary_flags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), 'poppy seed', 'Poppy Seed', ARRAY[]::varchar[], false, ARRAY[]::varchar[], ARRAY[]::varchar[], '#{now}', '#{now}')
    ON CONFLICT (name) DO NOTHING
    """

    execute """
    INSERT INTO canonical_ingredients (id, name, display_name, aliases, is_allergen, allergen_groups, dietary_flags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), 'sardine', 'Sardine', ARRAY[]::varchar[], false, ARRAY[]::varchar[], ARRAY[]::varchar[], '#{now}', '#{now}')
    ON CONFLICT (name) DO NOTHING
    """

    # Remove the aliases we added
    execute """
    UPDATE canonical_ingredients SET aliases = array_remove(aliases, 'zaatar') WHERE name = 'za''atar'
    """

    execute """
    UPDATE canonical_ingredients SET aliases = array_remove(aliases, 'andouille sausages') WHERE name = 'andouille sausage'
    """

    execute """
    UPDATE canonical_ingredients SET aliases = array_remove(aliases, 'poppy seed') WHERE name = 'poppy seeds'
    """

    execute """
    UPDATE canonical_ingredients SET aliases = array_remove(aliases, 'sardine') WHERE name = 'sardines'
    """
  end
end
