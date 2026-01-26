defmodule Controlcopypasta.Repo.Migrations.AddArchivedAtToRecipes do
  use Ecto.Migration

  def change do
    alter table(:recipes) do
      add :archived_at, :utc_datetime
    end

    create index(:recipes, [:archived_at])
  end
end
