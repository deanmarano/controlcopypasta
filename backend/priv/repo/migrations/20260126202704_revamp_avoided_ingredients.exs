defmodule Controlcopypasta.Repo.Migrations.RevampAvoidedIngredients do
  use Ecto.Migration

  def up do
    alter table(:avoided_ingredients) do
      add :canonical_ingredient_id,
          references(:canonical_ingredients, type: :binary_id, on_delete: :delete_all)

      add :avoidance_type, :string, null: false, default: "ingredient"
      add :category, :string
      add :allergen_group, :string
    end

    # Make canonical_name nullable since category/allergen avoidances won't have it
    execute "ALTER TABLE avoided_ingredients ALTER COLUMN canonical_name DROP NOT NULL"

    # Drop the old unique index
    drop index(:avoided_ingredients, [:user_id, :canonical_name])

    # Create partial unique indexes for each avoidance type
    create index(:avoided_ingredients, [:user_id, :canonical_ingredient_id],
             unique: true,
             where: "avoidance_type = 'ingredient' AND canonical_ingredient_id IS NOT NULL",
             name: :avoided_ingredients_user_ingredient_idx
           )

    create index(:avoided_ingredients, [:user_id, :category],
             unique: true,
             where: "avoidance_type = 'category' AND category IS NOT NULL",
             name: :avoided_ingredients_user_category_idx
           )

    create index(:avoided_ingredients, [:user_id, :allergen_group],
             unique: true,
             where: "avoidance_type = 'allergen' AND allergen_group IS NOT NULL",
             name: :avoided_ingredients_user_allergen_idx
           )

    # Keep a unique index for text-based ingredient avoidances (backward compat)
    create index(:avoided_ingredients, [:user_id, :canonical_name],
             unique: true,
             where: "avoidance_type = 'ingredient' AND canonical_name IS NOT NULL",
             name: :avoided_ingredients_user_canonical_name_idx
           )
  end

  def down do
    # Drop the new partial indexes
    drop_if_exists index(:avoided_ingredients, [:user_id, :canonical_ingredient_id],
                     name: :avoided_ingredients_user_ingredient_idx
                   )

    drop_if_exists index(:avoided_ingredients, [:user_id, :category],
                     name: :avoided_ingredients_user_category_idx
                   )

    drop_if_exists index(:avoided_ingredients, [:user_id, :allergen_group],
                     name: :avoided_ingredients_user_allergen_idx
                   )

    drop_if_exists index(:avoided_ingredients, [:user_id, :canonical_name],
                     name: :avoided_ingredients_user_canonical_name_idx
                   )

    # Delete any rows that don't have a canonical_name (category/allergen avoidances)
    execute "DELETE FROM avoided_ingredients WHERE canonical_name IS NULL"

    # Restore NOT NULL constraint
    execute "ALTER TABLE avoided_ingredients ALTER COLUMN canonical_name SET NOT NULL"

    # Restore original unique index
    create unique_index(:avoided_ingredients, [:user_id, :canonical_name])

    alter table(:avoided_ingredients) do
      remove :canonical_ingredient_id
      remove :avoidance_type
      remove :category
      remove :allergen_group
    end
  end
end
