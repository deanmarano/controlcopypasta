defmodule Controlcopypasta.Repo.Migrations.CreateDomains do
  use Ecto.Migration

  def change do
    create table(:domains, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :domain, :string, null: false
      add :display_name, :string
      add :favicon_url, :string
      add :screenshot, :binary
      add :screenshot_captured_at, :utc_datetime

      timestamps()
    end

    create unique_index(:domains, [:domain])
  end
end
