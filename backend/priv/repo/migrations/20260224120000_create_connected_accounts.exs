defmodule Controlcopypasta.Repo.Migrations.CreateConnectedAccounts do
  use Ecto.Migration

  def change do
    create table(:connected_accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :provider, :string, null: false
      add :provider_username, :string, null: false
      add :linked_at, :utc_datetime_usec, default: fragment("now()"), null: false

      timestamps()
    end

    create unique_index(:connected_accounts, [:provider, :provider_username])
    create index(:connected_accounts, [:user_id])
  end
end
