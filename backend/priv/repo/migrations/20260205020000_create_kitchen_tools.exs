defmodule Controlcopypasta.Repo.Migrations.CreateKitchenTools do
  use Ecto.Migration

  def change do
    create table(:kitchen_tools, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :display_name, :string, null: false
      add :category, :string
      add :aliases, {:array, :string}, default: []
      add :metadata, :map, default: %{}

      timestamps()
    end

    create unique_index(:kitchen_tools, [:name])
    create index(:kitchen_tools, [:category])
    create index(:kitchen_tools, [:aliases], using: :gin)
  end
end
