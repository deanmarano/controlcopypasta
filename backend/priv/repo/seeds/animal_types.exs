# Fix missing animal_type on canonical ingredients
#
# Run with: mix run priv/repo/seeds/animal_types.exs
#
# Sets animal_type for ingredients that should be associated with an animal
# for proper avoidance filtering. Safe to re-run.

alias Controlcopypasta.Repo
alias Controlcopypasta.Ingredients.CanonicalIngredient
import Ecto.Query

IO.puts("Setting animal_type on canonical ingredients...")

# {canonical_name, animal_type}
animal_type_updates = [
  # === BEEF ===
  {"beef broth", "beef"},
  {"beef eye of round", "beef"},
  {"beef short rib", "beef"},
  {"beef stew meat", "beef"},

  # === CHICKEN ===
  {"chicken broth", "chicken"},
  {"schmaltz", "chicken"},

  # === PORK ===
  {"cocktail sausage", "pork"},
  {"breakfast sausage", "pork"},
  {"hot dog", "pork"},
  {"kielbasa", "pork"},
  {"mortadella", "pork"},
  {"salami", "pork"},
  {"lard", "pork"},

  # === DUCK ===
  {"duck breast", "duck"},

  # === LAMB ===
  {"lamb shoulder", "lamb"},

  # === SEAFOOD ===
  {"anchovy paste", "anchovy"},
  {"bonito flakes", "fish"},
  {"dover sole", "fish"},
  {"escargot", "snail"},
  {"mixed seafood", "seafood"},
  {"octopus", "octopus"},
  {"odeng", "fish"},
  {"whitefish", "fish"},
  {"lobster tail", "lobster"},

  # === GELATIN (typically beef/pork derived) ===
  {"gelatin", "beef"},
]

# Clear incorrect empty-string animal_types
IO.puts("  Clearing empty-string animal_types...")
{cleared, _} = Repo.update_all(
  from(c in CanonicalIngredient, where: c.animal_type == ""),
  set: [animal_type: nil]
)
IO.puts("  Cleared #{cleared} empty-string entries")

# Apply updates
updated = Enum.reduce(animal_type_updates, 0, fn {name, animal_type}, acc ->
  case Repo.one(from c in CanonicalIngredient, where: c.name == ^name) do
    nil ->
      IO.puts("  WARNING: '#{name}' not found, skipping")
      acc

    ingredient ->
      if ingredient.animal_type == animal_type do
        acc
      else
        changeset = Ecto.Changeset.change(ingredient, %{animal_type: animal_type})
        case Repo.update(changeset) do
          {:ok, _} ->
            if ingredient.animal_type do
              IO.puts("  Updated '#{name}': #{ingredient.animal_type} -> #{animal_type}")
            else
              IO.puts("  Set '#{name}' -> #{animal_type}")
            end
            acc + 1
          {:error, reason} ->
            IO.puts("  ERROR updating '#{name}': #{inspect(reason)}")
            acc
        end
      end
  end
end)

IO.puts("\n  Updated #{updated} canonical ingredients with animal_type")
IO.puts("Animal type seeding complete!")
