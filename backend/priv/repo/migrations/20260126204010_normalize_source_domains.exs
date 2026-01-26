defmodule Controlcopypasta.Repo.Migrations.NormalizeSourceDomains do
  use Ecto.Migration

  def up do
    # Remove www. prefix from source_domain in recipes
    execute """
    UPDATE recipes
    SET source_domain = regexp_replace(source_domain, '^www\\.', '')
    WHERE source_domain LIKE 'www.%'
    """
  end

  def down do
    # Can't reliably restore www. prefixes
    :ok
  end
end
