defmodule Controlcopypasta.Repo.Migrations.AddHideAvoidedPreference do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :hide_avoided_ingredients, :boolean, default: false, null: false
    end
  end
end
