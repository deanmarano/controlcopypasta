# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# All seed files use upsert logic (on_conflict: :nothing or upsert_density)
# so they are safe to run multiple times.

# 1. Canonical ingredients and preparations (base data, no dependencies)
Code.eval_file("priv/repo/seeds/ingredients.exs")

# 2. Additional ingredients for recipe nutrition completeness
Code.eval_file("priv/repo/seeds/recipe_nutrition_completeness.exs")

# 3. Ingredient densities (depends on canonical ingredients)
Code.eval_file("priv/repo/seeds/ingredient_densities.exs")

# 4. Expanded densities (depends on canonical ingredients)
Code.eval_file("priv/repo/seeds/ingredient_densities_expanded.exs")

# 5. Brand package sizes (depends on canonical ingredients)
Code.eval_file("priv/repo/seeds/brand_package_sizes.exs")
