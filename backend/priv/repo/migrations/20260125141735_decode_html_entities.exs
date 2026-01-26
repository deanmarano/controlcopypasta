defmodule Controlcopypasta.Repo.Migrations.DecodeHtmlEntities do
  use Ecto.Migration

  def up do
    # Decode HTML entities in recipe titles
    # Using CHR(39) for apostrophe to avoid escaping issues
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&amp;', '&') WHERE title LIKE '%&amp;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#39;', CHR(39)) WHERE title LIKE '%&#39;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#039;', CHR(39)) WHERE title LIKE '%&#039;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&quot;', '"') WHERE title LIKE '%&quot;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#8211;', '–') WHERE title LIKE '%&#8211;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#8217;', CHR(8217)) WHERE title LIKE '%&#8217;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#8220;', CHR(8220)) WHERE title LIKE '%&#8220;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#8221;', CHR(8221)) WHERE title LIKE '%&#8221;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&lt;', '<') WHERE title LIKE '%&lt;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&gt;', '>') WHERE title LIKE '%&gt;%';|

    # Decode HTML entities in ingredients JSONB (cast to text, replace, cast back)
    # Note: &quot; must become \" (escaped quote) inside JSON strings
    execute ~s|
    UPDATE recipes
    SET ingredients = REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(ingredients::text, '&amp;', '&'),
          '&#39;', ''''),
        '&#039;', ''''),
      '&#8217;', E'\u2019'),
    '&quot;', '\\"')::jsonb
    WHERE ingredients::text LIKE '%&amp;%'
       OR ingredients::text LIKE '%&#39;%'
       OR ingredients::text LIKE '%&#039;%'
       OR ingredients::text LIKE '%&#8217;%'
       OR ingredients::text LIKE '%&quot;%';
    |

    # Decode HTML entities in instructions JSONB
    execute ~s|
    UPDATE recipes
    SET instructions = REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(instructions::text, '&amp;', '&'),
          '&#39;', ''''),
        '&#039;', ''''),
      '&#8217;', E'\u2019'),
    '&quot;', '\\"')::jsonb
    WHERE instructions::text LIKE '%&amp;%'
       OR instructions::text LIKE '%&#39;%'
       OR instructions::text LIKE '%&#039;%'
       OR instructions::text LIKE '%&#8217;%'
       OR instructions::text LIKE '%&quot;%';
    |
  end

  def down do
    # Cannot reliably reverse this migration
    :ok
  end
end
