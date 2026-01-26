defmodule Controlcopypasta.Repo.Migrations.DecodeAdditionalHtmlEntities do
  use Ecto.Migration

  def up do
    # Numeric fraction entities
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#188;', '¼') WHERE title LIKE '%&#188;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#189;', '½') WHERE title LIKE '%&#189;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#190;', '¾') WHERE title LIKE '%&#190;%';|

    # Named fraction entities
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&frac14;', '¼') WHERE title LIKE '%&frac14;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&frac12;', '½') WHERE title LIKE '%&frac12;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&frac34;', '¾') WHERE title LIKE '%&frac34;%';|

    # Other common entities in titles
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#233;', 'é') WHERE title LIKE '%&#233;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&eacute;', 'é') WHERE title LIKE '%&eacute;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#8211;', '–') WHERE title LIKE '%&#8211;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&#8230;', '…') WHERE title LIKE '%&#8230;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&nbsp;', ' ') WHERE title LIKE '%&nbsp;%';|
    execute ~s|UPDATE recipes SET title = REPLACE(title, '&deg;', '°') WHERE title LIKE '%&deg;%';|

    # JSONB fields - ingredients
    execute ~s|
    UPDATE recipes
    SET ingredients = REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(ingredients::text, '&#188;', '¼'),
                        '&#189;', '½'),
                      '&#190;', '¾'),
                    '&frac14;', '¼'),
                  '&frac12;', '½'),
                '&frac34;', '¾'),
              '&#233;', 'é'),
            '&eacute;', 'é'),
          '&#8211;', '–'),
        '&#8230;', '…'),
      '&nbsp;', ' '),
    '&deg;', '°')::jsonb
    WHERE ingredients::text LIKE '%&#188;%'
       OR ingredients::text LIKE '%&#189;%'
       OR ingredients::text LIKE '%&#190;%'
       OR ingredients::text LIKE '%&frac14;%'
       OR ingredients::text LIKE '%&frac12;%'
       OR ingredients::text LIKE '%&frac34;%'
       OR ingredients::text LIKE '%&#233;%'
       OR ingredients::text LIKE '%&eacute;%'
       OR ingredients::text LIKE '%&#8211;%'
       OR ingredients::text LIKE '%&#8230;%'
       OR ingredients::text LIKE '%&nbsp;%'
       OR ingredients::text LIKE '%&deg;%';
    |

    # JSONB fields - instructions
    execute ~s|
    UPDATE recipes
    SET instructions = REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(instructions::text, '&#188;', '¼'),
                        '&#189;', '½'),
                      '&#190;', '¾'),
                    '&frac14;', '¼'),
                  '&frac12;', '½'),
                '&frac34;', '¾'),
              '&#233;', 'é'),
            '&eacute;', 'é'),
          '&#8211;', '–'),
        '&#8230;', '…'),
      '&nbsp;', ' '),
    '&deg;', '°')::jsonb
    WHERE instructions::text LIKE '%&#188;%'
       OR instructions::text LIKE '%&#189;%'
       OR instructions::text LIKE '%&#190;%'
       OR instructions::text LIKE '%&frac14;%'
       OR instructions::text LIKE '%&frac12;%'
       OR instructions::text LIKE '%&frac34;%'
       OR instructions::text LIKE '%&#233;%'
       OR instructions::text LIKE '%&eacute;%'
       OR instructions::text LIKE '%&#8211;%'
       OR instructions::text LIKE '%&#8230;%'
       OR instructions::text LIKE '%&nbsp;%'
       OR instructions::text LIKE '%&deg;%';
    |
  end

  def down do
    # Cannot reliably reverse this migration
    :ok
  end
end
