defmodule Controlcopypasta.Repo.Migrations.AddMatchingRulesToCanonicalIngredients do
  use Ecto.Migration

  def change do
    alter table(:canonical_ingredients) do
      add :matching_rules, :map
    end
  end
end
