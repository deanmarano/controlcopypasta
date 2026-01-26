defmodule Controlcopypasta.Repo.Migrations.CreateScrapeUrls do
  use Ecto.Migration

  def change do
    create table(:scrape_urls, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :text, null: false
      add :domain, :text, null: false
      add :status, :text, default: "pending", null: false
      add :error, :text
      add :recipe_id, references(:recipes, type: :binary_id, on_delete: :nilify_all)
      add :attempts, :integer, default: 0, null: false

      timestamps()
    end

    create unique_index(:scrape_urls, [:url])
    create index(:scrape_urls, [:domain])
    create index(:scrape_urls, [:status])
  end
end
