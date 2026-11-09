defmodule Controlcopypasta.Repo.Migrations.WidenPendingIngredientTextColumns do
  use Ecto.Migration

  # Ecto's `:string` becomes varchar(255). `sample_texts` holds raw recipe
  # lines, 15 of which exceed 255 characters (longest: 590), and a single one
  # aborted a full scan with
  #   ERROR 22001 (string_data_right_truncation)
  # after 35 minutes of work. None of these columns has a reason to be bounded.

  def up do
    alter table(:pending_ingredients) do
      modify :name, :text
      modify :sample_texts, {:array, :text}
      modify :status, :text
      modify :rejected_by_rule, :text
      modify :fatsecret_id, :text
      modify :fatsecret_name, :text
      modify :suggested_display_name, :text
      modify :suggested_category, :text
      modify :suggested_aliases, {:array, :text}
    end
  end

  def down do
    # Narrowing back would truncate rows that are now legal, so this is a
    # one-way change.
    :ok
  end
end
