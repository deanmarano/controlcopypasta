defmodule Controlcopypasta.Repo.Migrations.ShipMissingCanonicalIngredients do
  use Ecto.Migration

  # Seventeen canonical ingredients existed in the seeded dev catalog but not
  # in production: 895 canonicals in dev against 871 in production. Seeds run
  # through `mix`, which a release does not have, so anything added to
  # priv/repo/seeds has never reached production. This is the same gap that
  # left expanded_aliases.exs with no effect.
  #
  # Rows were generated from the dev database rather than retyped, so the
  # nutrition and density values are the ones the seeds produce.
  #
  # Shipped here:
  #   - anchovy fillet
  #   - anise extract
  #   - caciocavallo
  #   - chocolate shavings
  #   - chocolate wafer
  #   - condensed milk
  #   - cottage cheese
  #   - durum wheat
  #   - fontina cheese
  #   - onion powder
  #   - protein powder
  #   - red chili
  #   - red chili flakes
  #   - sandwich bread
  #   - split peas
  #   - sun-dried tomatoes
  #   - yeast extract spread
  #
  # Twelve further canonicals are held back because their NAME is already a
  # lookup key in production, owned by another canonical: shipping them would
  # move that key rather than add one. They need a decision each:
  #   ancho chili powder, asafoetida, cornmeal, diamond crystal salt,
  #   grape tomatoes, green chili, instant yeast, kosher salt, lobster tail,
  #   morton salt, pita bread, vanilla extract
  #
  # Six of the seventeen keep their name but drop an alias that production
  # already uses for something else:
  #   anchovy fillet   drops "anchovies", "anchovy fillets"
  #   fontina cheese   drops "fontina"
  #   protein powder   drops "vanilla protein powder"
  #   red chili        drops "red chili pepper"   (production: red pepper flakes, dried)
  #   red chili flakes drops "chili flakes"
  #   sandwich bread   drops "pullman bread"
  #
  # Every statement is additive and idempotent.

  def up do
    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"farmers cheese"}', '{}', NULL, NULL, 'dairy', '{"vegetarian"}', 'Cottage Cheese', NULL, false, false, NULL, 'standard', 'cottage cheese', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"fontal","italian fontina"}', '{}', NULL, NULL, 'dairy', '{"vegetarian"}', 'Fontina Cheese', NULL, false, false, NULL, 'standard', 'fontina cheese', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"sweetened condensed milk"}', '{}', NULL, NULL, 'dairy', '{"vegetarian"}', 'Condensed Milk', NULL, false, false, NULL, 'standard', 'condensed milk', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"dried split peas","green split peas","yellow split peas"}', '{}', NULL, NULL, 'legume', '{"vegetarian","vegan","gluten_free"}', 'Split Peas', NULL, false, false, NULL, 'standard', 'split peas', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"durum wheat flour","semola","semola di grano duro","durum wheat semolina"}', '{"wheat","gluten"}', NULL, NULL, 'grain', '{}', 'Durum Wheat', NULL, true, false, NULL, 'standard', 'durum wheat', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"chile flakes","crushed chili flakes"}', '{}', NULL, NULL, 'spice', '{"vegetarian","vegan","gluten_free"}', 'Red Chili Flakes', NULL, false, false, NULL, 'standard', 'red chili flakes', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"anise flavoring"}', '{}', NULL, NULL, 'other', '{"vegetarian","vegan"}', 'Anise Extract', NULL, false, false, NULL, 'standard', 'anise extract', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"whey protein","protein powder scoop"}', '{}', NULL, NULL, 'other', '{"vegetarian"}', 'Protein Powder', NULL, false, false, NULL, 'standard', 'protein powder', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{}', '{}', NULL, NULL, 'spice', '{"vegetarian","vegan","gluten_free"}', 'Onion Powder', NULL, false, false, NULL, 'standard', 'onion powder', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"caciocavallo cheese"}', '{}', NULL, NULL, 'dairy', '{"vegetarian"}', 'Caciocavallo', NULL, false, false, NULL, 'standard', 'caciocavallo', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{}', '{}', NULL, NULL, 'protein', '{"gluten_free","dairy_free"}', 'Anchovy Fillet', NULL, false, false, NULL, 'standard', 'anchovy fillet', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"red chile","red chiles","red chilies"}', '{}', NULL, NULL, 'produce', '{"vegetarian","vegan","gluten_free"}', 'Red Chili', NULL, false, false, NULL, 'standard', 'red chili', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"sundried tomatoes","sun dried tomatoes","sun-dried tomato"}', '{}', NULL, NULL, 'produce', '{"vegetarian","vegan","gluten_free"}', 'Sun-Dried Tomatoes', NULL, false, false, NULL, 'standard', 'sun-dried tomatoes', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"marmite","vegemite","yeast extract"}', '{}', NULL, NULL, 'condiment', '{"vegetarian","vegan"}', 'Yeast Extract Spread', NULL, false, false, NULL, 'standard', 'yeast extract spread', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"soft sandwich bread","white bread","sliced bread","sliced white bread"}', '{"wheat","gluten"}', NULL, NULL, 'grain', '{}', 'Sandwich Bread', NULL, true, false, NULL, 'standard', 'sandwich bread', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"chocolate curls"}', '{}', NULL, NULL, 'other', '{}', 'Chocolate Shavings', NULL, false, false, NULL, 'standard', 'chocolate shavings', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO canonical_ingredients (id, aliases, allergen_groups, animal_type, brand, category, dietary_flags, display_name, image_url, is_allergen, is_branded, matching_rules, measurement_type, name, parent_company, similarity_name, skip_nutrition, subcategory, tags, inserted_at, updated_at)
    VALUES (gen_random_uuid(), '{"chocolate wafers","chocolate disks","chocolate feves"}', '{}', NULL, NULL, 'other', '{}', 'Chocolate Wafer', NULL, false, false, NULL, 'standard', 'chocolate wafer', NULL, NULL, false, NULL, '{}', NOW(), NOW())
    ON CONFLICT DO NOTHING
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'chocolate wafer'), 31.0, 433.0, 72.7, 2.0, 0.76, '{"data_completeness":1.0,"source_reliability":0.95,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, 4.865, 4.153, 4.241, 14.2, NULL, 3.4, 47.0, 4.01, true, NULL, 53.0, 2.858, NULL, 132.0, 210.0, 6.6, NULL, 0.266, 'oz', 'g', 100, 580.0, 'usda', '172714', 'USDA FoodData Central - SR Legacy', 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/172714/nutrients', NULL, 37.43, 0.203, NULL, 3.0, 0.09, 0.051, 0.0, 0.0, 0.72, 2.4, 4.5, 1.09, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'chocolate wafer')
        AND x.source IS NOT DISTINCT FROM 'usda'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'red chili flakes'), NULL, 318, 56.63, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 17.27, NULL, 28.7, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 12.01, NULL, NULL, NULL, 'g', 100, 91, 'estimated', NULL, NULL, NULL, NULL, 10.34, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'red chili flakes')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'split peas'), NULL, 341, 60.37, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 1.16, NULL, 25.5, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 24.55, NULL, NULL, NULL, 'g', 100, 15, 'estimated', NULL, NULL, NULL, NULL, 8.0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'split peas')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'fontina cheese'), NULL, 389, 1.55, 116, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 31.14, NULL, 0.0, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 25.6, NULL, NULL, NULL, 'g', 100, 800, 'estimated', NULL, NULL, NULL, NULL, 0.0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'fontina cheese')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'durum wheat'), NULL, 339, 71.13, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 2.47, NULL, 4.6, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 13.68, NULL, NULL, NULL, 'g', 100, 2, 'estimated', NULL, NULL, NULL, NULL, 2.67, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'durum wheat')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'protein powder'), NULL, 370, 12.0, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 3.0, NULL, 1.0, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 75.0, NULL, NULL, NULL, 'g', 100, 500, 'estimated', NULL, NULL, NULL, NULL, 5.0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'protein powder')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'condensed milk'), NULL, 321, 54.4, 34, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 8.7, NULL, 0.0, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 7.91, NULL, NULL, NULL, 'g', 100, 127, 'estimated', NULL, NULL, NULL, NULL, 54.4, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'condensed milk')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'anise extract'), NULL, 288, 12.65, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 0.06, NULL, 0.0, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 0.06, NULL, NULL, NULL, 'g', 100, 9, 'estimated', NULL, NULL, NULL, NULL, 12.65, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'anise extract')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'cottage cheese'), NULL, 98, 3.38, 17, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 4.3, NULL, 0.0, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 11.12, NULL, NULL, NULL, 'g', 100, 364, 'estimated', NULL, NULL, NULL, NULL, 2.67, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'cottage cheese')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'onion powder'), NULL, 341, 79.12, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 1.04, NULL, 15.2, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 10.41, NULL, NULL, NULL, 'g', 100, 73, 'estimated', NULL, NULL, NULL, NULL, 6.58, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'onion powder')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'caciocavallo'), NULL, 387, 2.2, 109, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 30.8, NULL, 0.0, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 25.6, NULL, NULL, NULL, 'g', 100, 730, 'estimated', NULL, NULL, NULL, NULL, 0.0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'caciocavallo')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'anchovy fillet'), NULL, 210, 0.0, 60, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 9.71, NULL, 0.0, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 28.89, NULL, NULL, NULL, 'g', 100, 3668, 'estimated', NULL, NULL, NULL, NULL, 0.0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'anchovy fillet')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'red chili'), NULL, 40, 8.81, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 0.44, NULL, 1.5, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 1.87, NULL, NULL, NULL, 'g', 100, 9, 'estimated', NULL, NULL, NULL, NULL, 5.3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'red chili')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'sun-dried tomatoes'), NULL, 258, 55.76, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 2.97, NULL, 12.3, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 14.11, NULL, NULL, NULL, 'g', 100, 2095, 'estimated', NULL, NULL, NULL, NULL, 37.59, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'sun-dried tomatoes')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'yeast extract spread'), NULL, 185, 23.9, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 0.11, NULL, 3.5, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 27.8, NULL, NULL, NULL, 'g', 100, 3400, 'estimated', NULL, NULL, NULL, NULL, 1.3, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'yeast extract spread')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'sandwich bread'), NULL, 265, 49.0, 0, 0.43, '{"data_completeness":1.0,"source_reliability":0.3,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, NULL, NULL, NULL, 3.59, NULL, 2.7, NULL, NULL, false, NULL, NULL, NULL, NULL, NULL, NULL, 9.43, NULL, NULL, NULL, 'g', 100, 491, 'estimated', NULL, NULL, NULL, NULL, 5.67, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'sandwich bread')
        AND x.source IS NOT DISTINCT FROM 'estimated'
    )
    """)

    execute("""
    INSERT INTO ingredient_nutrition (id, canonical_ingredient_id, calcium_mg, calories, carbohydrates_g, cholesterol_mg, confidence, confidence_factors, fat_monounsaturated_g, fat_polyunsaturated_g, fat_saturated_g, fat_total_g, fat_trans_g, fiber_g, folate_mcg, iron_mg, is_primary, last_checked_at, magnesium_mg, niacin_mg, notes, phosphorus_mg, potassium_mg, protein_g, retrieved_at, riboflavin_mg, serving_description, serving_size_unit, serving_size_value, sodium_mg, source, source_id, source_name, source_url, sugar_added_g, sugar_g, thiamin_mg, verified_at, vitamin_a_mcg, vitamin_b12_mcg, vitamin_b6_mg, vitamin_c_mg, vitamin_d_mcg, vitamin_e_mg, vitamin_k_mcg, water_g, zinc_mg, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'chocolate shavings'), 14.0, 279.0, 65.1, 0.0, 0.76, '{"data_completeness":1.0,"source_reliability":0.95,"staleness_penalty":0.2,"verified_bonus":0.0}'::jsonb, 0.286, 0.026, 0.519, 1.13, NULL, 2.6, 2.0, 2.11, true, NULL, 65.0, 0.322, NULL, 129.0, 224.0, 2.1, NULL, 0.05, 'cup', 'g', 100, 72.0, 'usda', '174117', 'USDA FoodData Central - SR Legacy', 'https://fdc.nal.usda.gov/fdc-app.html#/food-details/174117/nutrients', NULL, 49.65, 0.009, NULL, 0.0, 0.0, 0.006, 0.2, 0.0, 0.02, 0.5, 31.0, 0.73, NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_nutrition x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'chocolate shavings')
        AND x.source IS NOT DISTINCT FROM 'usda'
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'yeast extract spread'), NULL, NULL, 15.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'tbsp', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'yeast extract spread')
        AND x.volume_unit IS NOT DISTINCT FROM 'tbsp'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'onion powder'), NULL, NULL, 2.4, NULL, NULL, NULL, NULL, 'usda', NULL, NULL, 'tsp', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'onion powder')
        AND x.volume_unit IS NOT DISTINCT FROM 'tsp'
        AND x.source IS NOT DISTINCT FROM 'usda'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'cottage cheese'), NULL, NULL, 226, NULL, NULL, NULL, NULL, 'usda', NULL, NULL, 'cup', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'cottage cheese')
        AND x.volume_unit IS NOT DISTINCT FROM 'cup'
        AND x.source IS NOT DISTINCT FROM 'usda'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'split peas'), NULL, NULL, 196, NULL, NULL, NULL, NULL, 'usda', NULL, NULL, 'cup', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'split peas')
        AND x.volume_unit IS NOT DISTINCT FROM 'cup'
        AND x.source IS NOT DISTINCT FROM 'usda'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'condensed milk'), NULL, NULL, 306, NULL, NULL, NULL, NULL, 'usda', NULL, NULL, 'cup', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'condensed milk')
        AND x.volume_unit IS NOT DISTINCT FROM 'cup'
        AND x.source IS NOT DISTINCT FROM 'usda'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'sun-dried tomatoes'), NULL, NULL, 110, NULL, NULL, NULL, NULL, 'usda', NULL, NULL, 'cup', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'sun-dried tomatoes')
        AND x.volume_unit IS NOT DISTINCT FROM 'cup'
        AND x.source IS NOT DISTINCT FROM 'usda'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'anchovy fillet'), NULL, NULL, 10, NULL, NULL, 'minced', NULL, 'usda', NULL, NULL, 'tbsp', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'anchovy fillet')
        AND x.volume_unit IS NOT DISTINCT FROM 'tbsp'
        AND x.source IS NOT DISTINCT FROM 'usda'
        AND x.preparation IS NOT DISTINCT FROM 'minced'
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'cottage cheese'), NULL, NULL, 226.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'cup', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'cottage cheese')
        AND x.volume_unit IS NOT DISTINCT FROM 'cup'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'condensed milk'), NULL, NULL, 306.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'cup', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'condensed milk')
        AND x.volume_unit IS NOT DISTINCT FROM 'cup'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'anchovy fillet'), NULL, NULL, 4.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'each', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'anchovy fillet')
        AND x.volume_unit IS NOT DISTINCT FROM 'each'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'condensed milk'), NULL, NULL, 397.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'can', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'condensed milk')
        AND x.volume_unit IS NOT DISTINCT FROM 'can'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'protein powder'), NULL, NULL, 30.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'each', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'protein powder')
        AND x.volume_unit IS NOT DISTINCT FROM 'each'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'sandwich bread'), NULL, NULL, 28.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'slice', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'sandwich bread')
        AND x.volume_unit IS NOT DISTINCT FROM 'slice'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'sandwich bread'), NULL, NULL, 28.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'each', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'sandwich bread')
        AND x.volume_unit IS NOT DISTINCT FROM 'each'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'fontina cheese'), NULL, NULL, 132.0, NULL, NULL, 'shredded', NULL, 'manual', NULL, NULL, 'cup', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'fontina cheese')
        AND x.volume_unit IS NOT DISTINCT FROM 'cup'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM 'shredded'
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'sun-dried tomatoes'), NULL, NULL, 7.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'tbsp', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'sun-dried tomatoes')
        AND x.volume_unit IS NOT DISTINCT FROM 'tbsp'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'sun-dried tomatoes'), NULL, NULL, 54.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'cup', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'sun-dried tomatoes')
        AND x.volume_unit IS NOT DISTINCT FROM 'cup'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'red chili'), NULL, NULL, 10.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'each', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'red chili')
        AND x.volume_unit IS NOT DISTINCT FROM 'each'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)

    execute("""
    INSERT INTO ingredient_densities (id, canonical_ingredient_id, confidence, data_points, grams_per_unit, last_checked_at, notes, preparation, retrieved_at, source, source_id, source_url, volume_unit, inserted_at, updated_at)
    SELECT gen_random_uuid(), (SELECT id FROM canonical_ingredients WHERE name = 'yeast extract spread'), NULL, NULL, 5.0, NULL, NULL, NULL, NULL, 'manual', NULL, NULL, 'tsp', NOW(), NOW()
    WHERE NOT EXISTS (
      SELECT 1 FROM ingredient_densities x WHERE x.canonical_ingredient_id = (SELECT id FROM canonical_ingredients WHERE name = 'yeast extract spread')
        AND x.volume_unit IS NOT DISTINCT FROM 'tsp'
        AND x.source IS NOT DISTINCT FROM 'manual'
        AND x.preparation IS NOT DISTINCT FROM NULL
    )
    """)
  end

  def down, do: :ok
end
