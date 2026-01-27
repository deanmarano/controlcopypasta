defmodule Controlcopypasta.Repo.Migrations.FixHtmlEntitiesInRecipes do
  use Ecto.Migration

  def up do
    # Fix common HTML entities in recipe titles and descriptions
    # Order matters: decode &amp; last since other entities contain &
    execute """
    UPDATE recipes
    SET title = REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(title, '&#8217;', E'\\u2019'),
                    '&#8216;', E'\\u2018'),
                  '&#8220;', E'\\u201C'),
                '&#8221;', E'\\u201D'),
              '&#8211;', E'\\u2013'),
            '&#8212;', E'\\u2014'),
          '&apos;', ''''),
        '&#39;', ''''),
      '&quot;', '"'),
    '&amp;', '&')
    WHERE title LIKE '%&%'
    """

    execute """
    UPDATE recipes
    SET description = REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(description, '&#8217;', E'\\u2019'),
                    '&#8216;', E'\\u2018'),
                  '&#8220;', E'\\u201C'),
                '&#8221;', E'\\u201D'),
              '&#8211;', E'\\u2013'),
            '&#8212;', E'\\u2014'),
          '&apos;', ''''),
        '&#39;', ''''),
      '&quot;', '"'),
    '&amp;', '&')
    WHERE description LIKE '%&%'
    """
  end

  def down do
    # No-op: we don't want to re-encode entities
    :ok
  end
end
