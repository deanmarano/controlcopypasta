defmodule Controlcopypasta.Repo.Migrations.AddBrandToCanonicalIngredients do
  use Ecto.Migration

  def change do
    alter table(:canonical_ingredients) do
      # Brand name (e.g., "Sprite", "Coca-Cola")
      add :brand, :string
      # Parent company (e.g., "The Coca-Cola Company", "PepsiCo")
      add :parent_company, :string
      # Whether this is a branded/trademarked product
      add :is_branded, :boolean, default: false
    end

    # Index for querying by brand or parent company
    create index(:canonical_ingredients, [:brand])
    create index(:canonical_ingredients, [:parent_company])
    create index(:canonical_ingredients, [:is_branded])
  end
end
