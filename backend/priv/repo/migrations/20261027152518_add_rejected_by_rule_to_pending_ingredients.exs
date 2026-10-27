defmodule Controlcopypasta.Repo.Migrations.AddRejectedByRuleToPendingIngredients do
  use Ecto.Migration

  def change do
    alter table(:pending_ingredients) do
      # Names the blacklist rule that auto-rejected this ingredient.
      # NULL means a human made the decision, which keeps machine labels and
      # human labels distinguishable when training on this table.
      add :rejected_by_rule, :string
    end

    create index(:pending_ingredients, [:rejected_by_rule])
  end
end
