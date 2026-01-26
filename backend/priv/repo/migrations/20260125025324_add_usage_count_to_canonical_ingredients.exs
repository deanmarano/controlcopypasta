defmodule Controlcopypasta.Repo.Migrations.AddUsageCountToCanonicalIngredients do
  use Ecto.Migration

  def change do
    alter table(:canonical_ingredients) do
      add :usage_count, :integer, default: 0
    end

    create index(:canonical_ingredients, [:usage_count])
  end
end
