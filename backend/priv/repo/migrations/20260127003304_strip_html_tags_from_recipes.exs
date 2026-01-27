defmodule Controlcopypasta.Repo.Migrations.StripHtmlTagsFromRecipes do
  use Ecto.Migration

  def up do
    # Strip HTML tags from recipe titles
    execute """
    UPDATE recipes
    SET title = TRIM(regexp_replace(title, '<[^>]*>', '', 'g'))
    WHERE title ~ '<[^>]*>'
    """

    # Strip HTML tags from recipe descriptions
    execute """
    UPDATE recipes
    SET description = TRIM(regexp_replace(description, '<[^>]*>', '', 'g'))
    WHERE description ~ '<[^>]*>'
    """

    # Normalize multiple spaces to single space
    execute """
    UPDATE recipes
    SET title = regexp_replace(title, '\\s+', ' ', 'g')
    WHERE title ~ '\\s{2,}'
    """

    execute """
    UPDATE recipes
    SET description = regexp_replace(description, '\\s+', ' ', 'g')
    WHERE description ~ '\\s{2,}'
    """
  end

  def down do
    # No-op: we can't restore stripped HTML
    :ok
  end
end
