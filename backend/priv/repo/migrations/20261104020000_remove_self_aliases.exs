defmodule Controlcopypasta.Repo.Migrations.RemoveSelfAliases do
  use Ecto.Migration

  @moduledoc """
  Removes aliases that merely repeat their own ingredient's name.

  These were introduced by the alias repair in #8. That file had entries like
  `{"chia seed", ["chia seeds", ...]}` pointing at a canonical ingredient that
  does not exist; retargeting them to the real name produced
  `{"chia seeds", ["chia seeds", ...]}`, so 17 ingredients ended up listing
  their own name among their aliases.

  Matching is unaffected either way -- the key resolves to the same ingredient
  whichever entry wins -- but they show up as collisions in the catalog audit
  that found the 158 contested keys, and that audit is more useful without
  self-inflicted noise in it.
  """

  def up do
    repo().query!("""
    UPDATE canonical_ingredients
    SET aliases = (
          SELECT coalesce(array_agg(a ORDER BY ord), '{}')
          FROM unnest(aliases) WITH ORDINALITY AS t(a, ord)
          WHERE lower(a) <> lower(canonical_ingredients.name)
        ),
        updated_at = NOW()
    WHERE lower(name) = ANY (SELECT lower(a) FROM unnest(aliases) AS a)
    """)
  end

  # Re-adding a name as its own alias would restore noise, not behaviour.
  def down, do: :ok
end
