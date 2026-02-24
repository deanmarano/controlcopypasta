defmodule Controlcopypasta.Repo.Migrations.AddObanTables do
  use Ecto.Migration

  # Oban was previously used but has been removed. The migration is kept as a
  # no-op so existing databases that already ran it don't see a gap in the
  # migration history.
  def up, do: :ok
  def down, do: :ok
end
