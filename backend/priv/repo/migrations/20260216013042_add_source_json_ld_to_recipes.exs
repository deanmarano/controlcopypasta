defmodule Controlcopypasta.Repo.Migrations.AddSourceJsonLdToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :source_json_ld, :map
    end
  end
end
