defmodule Controlcopypasta.Repo.Migrations.AddImageToCanonicalIngredients do
  use Ecto.Migration

  def change do
    alter table(:canonical_ingredients) do
      add :image_url, :string
    end
  end
end
