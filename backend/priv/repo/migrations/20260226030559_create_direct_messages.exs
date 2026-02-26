defmodule Controlcopypasta.Repo.Migrations.CreateDirectMessages do
  use Ecto.Migration

  def change do
    create table(:direct_messages, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :connected_account_id,
          references(:connected_accounts, type: :binary_id, on_delete: :delete_all),
          null: false

      add :message_text, :text
      add :message_type, :string, null: false
      add :sender_username, :string, null: false
      add :platform_message_id, :string
      add :platform_timestamp, :utc_datetime_usec
      add :shared_content, :map
      add :forwarded_content, :map
      add :processed_at, :utc_datetime_usec

      timestamps()
    end

    create index(:direct_messages, [:connected_account_id])
    create index(:direct_messages, [:connected_account_id, :inserted_at])

    create unique_index(:direct_messages, [:platform_message_id],
             where: "platform_message_id IS NOT NULL"
           )

    create table(:dm_extracted_urls, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :direct_message_id,
          references(:direct_messages, type: :binary_id, on_delete: :delete_all),
          null: false

      add :url, :text, null: false
      add :source, :string, null: false
      add :parse_status, :string, null: false, default: "pending"
      add :parse_error, :text
      add :parsed_recipe_data, :map

      add :recipe_id, references(:recipes, type: :binary_id, on_delete: :nilify_all)

      timestamps()
    end

    create index(:dm_extracted_urls, [:direct_message_id])
    create index(:dm_extracted_urls, [:recipe_id])
  end
end
