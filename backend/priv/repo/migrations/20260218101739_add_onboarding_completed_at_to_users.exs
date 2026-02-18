defmodule Controlcopypasta.Repo.Migrations.AddOnboardingCompletedAtToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :onboarding_completed_at, :utc_datetime, null: true
    end

    # Backfill existing users so they skip the wizard
    execute "UPDATE users SET onboarding_completed_at = NOW()", ""
  end
end
