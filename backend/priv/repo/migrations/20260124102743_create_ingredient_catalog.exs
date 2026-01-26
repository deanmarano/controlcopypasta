defmodule Controlcopypasta.Repo.Migrations.CreateIngredientCatalog do
  use Ecto.Migration

  def change do
    # Canonical ingredient catalog with tags (flat, no hierarchy)
    create table(:canonical_ingredients, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :display_name, :string, null: false

      # Category tags (flat, searchable)
      add :category, :string
      add :subcategory, :string
      add :tags, {:array, :string}, default: []

      # Allergen tracking
      add :is_allergen, :boolean, default: false
      add :allergen_groups, {:array, :string}, default: []

      # Dietary flags
      add :dietary_flags, {:array, :string}, default: []

      # Aliases for matching
      add :aliases, {:array, :string}, default: []

      timestamps()
    end

    create unique_index(:canonical_ingredients, [:name])
    create index(:canonical_ingredients, [:category])
    create index(:canonical_ingredients, [:subcategory])
    create index(:canonical_ingredients, [:is_allergen])

    # GIN index for array searching on tags
    execute(
      "CREATE INDEX canonical_ingredients_tags_idx ON canonical_ingredients USING GIN (tags)",
      "DROP INDEX canonical_ingredients_tags_idx"
    )

    execute(
      "CREATE INDEX canonical_ingredients_allergen_groups_idx ON canonical_ingredients USING GIN (allergen_groups)",
      "DROP INDEX canonical_ingredients_allergen_groups_idx"
    )

    execute(
      "CREATE INDEX canonical_ingredients_dietary_flags_idx ON canonical_ingredients USING GIN (dietary_flags)",
      "DROP INDEX canonical_ingredients_dietary_flags_idx"
    )

    execute(
      "CREATE INDEX canonical_ingredients_aliases_idx ON canonical_ingredients USING GIN (aliases)",
      "DROP INDEX canonical_ingredients_aliases_idx"
    )

    # Standard preparation methods
    create table(:preparations, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :display_name, :string, null: false
      add :category, :string
      add :aliases, {:array, :string}, default: []

      timestamps()
    end

    create unique_index(:preparations, [:name])
    create index(:preparations, [:category])

    execute(
      "CREATE INDEX preparations_aliases_idx ON preparations USING GIN (aliases)",
      "DROP INDEX preparations_aliases_idx"
    )

    # Product forms (canned, frozen, dried)
    create table(:ingredient_forms, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :canonical_ingredient_id,
          references(:canonical_ingredients, type: :binary_id, on_delete: :delete_all),
          null: false

      add :form_name, :string, null: false
      add :default_unit, :string
      add :default_size_value, :decimal
      add :default_size_unit, :string

      timestamps()
    end

    create unique_index(:ingredient_forms, [:canonical_ingredient_id, :form_name])
    create index(:ingredient_forms, [:form_name])
  end
end
