defmodule Controlcopypasta.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :email, :string, null: false

      timestamps()
    end

    create unique_index(:users, [:email])

    # Add user_id to recipes for ownership
    alter table(:recipes) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
    end

    create index(:recipes, [:user_id])
  end
end
