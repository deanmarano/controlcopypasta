defmodule Controlcopypasta.Repo.Migrations.AddBritishPreparationWords do
  use Ecto.Migration

  # Preparations are read from the database at runtime (ParserCache), so the
  # defaults in ReferenceData.Preparations only reach dev and test. These are
  # the words the catalog lacked, nearly all British forms of ones it already
  # had. Without them the word stays in the ingredient name:
  #
  #   "1 red chilli deseeded and finely chopped" -> name "red chili deseeded"
  #
  # The pending-ingredient scan attributes roughly 3,700 unmatched lines to
  # these twelve names, led by "discarded" (683), "lengthways" (633),
  # "shelled" (511), "undrained" (479) and "scraped" (390).

  @preparations [
    {"deseeded", "Deseeded", "process", "deseed",
     ["de-seeded", "deseed", "de-seed", "seeds removed"]},
    {"destoned", "Destoned", "process", "destone", ["de-stoned", "destone"]},
    {"stoned", "Stoned", "process", "stone", []},
    {"podded", "Podded", "process", "pod", ["pod"]},
    {"shelled", "Shelled", "process", "shell", ["shell"]},
    {"scraped", "Scraped", "process", "scrape", ["scraped out", "scrape"]},
    {"discarded", "Discarded", "process", "discard", ["discard"]},
    {"undrained", "Undrained", "process", "leave undrained", ["not drained"]},
    {"lengthways", "Lengthways", "cut", "cut lengthways", ["lengthwise"]}
  ]

  def up do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    Enum.each(@preparations, fn {name, display, category, verb, aliases} ->
      execute("""
      INSERT INTO preparations (id, name, display_name, category, verb, metadata, aliases, inserted_at, updated_at)
      VALUES (
        gen_random_uuid(),
        #{q(name)},
        #{q(display)},
        #{q(category)},
        #{q(verb)},
        '{}'::jsonb,
        #{arr(aliases)},
        '#{now}',
        '#{now}'
      )
      ON CONFLICT (name) DO NOTHING
      """)
    end)
  end

  def down do
    names = Enum.map_join(@preparations, ",", fn {name, _, _, _, _} -> q(name) end)
    execute("DELETE FROM preparations WHERE name IN (#{names})")
  end

  defp q(nil), do: "NULL"
  defp q(s), do: "'" <> String.replace(s, "'", "''") <> "'"

  defp arr([]), do: "'{}'::varchar[]"

  defp arr(list) do
    inner = Enum.map_join(list, ",", fn s -> "\"" <> String.replace(s, "\"", "\\\"") <> "\"" end)
    "'{" <> inner <> "}'::varchar[]"
  end
end
