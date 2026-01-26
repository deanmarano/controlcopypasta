defmodule Controlcopypasta.Repo.Migrations.AddFatsecretToNutritionSource do
  use Ecto.Migration

  def up do
    execute("ALTER TYPE nutrition_source ADD VALUE 'fatsecret'")
  end

  def down do
    # PostgreSQL doesn't support removing enum values directly
    # Would need to recreate the type and migrate data
    :ok
  end
end
