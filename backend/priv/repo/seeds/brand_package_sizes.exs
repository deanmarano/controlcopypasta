# Seeds for brand package sizes
# Run with: mix run priv/repo/seeds/brand_package_sizes.exs

alias Controlcopypasta.Repo
alias Controlcopypasta.Ingredients
alias Controlcopypasta.Ingredients.{CanonicalIngredient, BrandPackageSize}
import Ecto.Query

# Helper to get ingredient by name
get_ingredient = fn name ->
  Repo.one(from i in CanonicalIngredient, where: i.name == ^name, select: i.id)
end

# Helper to create package size if it doesn't exist
create_package_size = fn ingredient_id, attrs ->
  if ingredient_id do
    attrs = Map.put(attrs, :canonical_ingredient_id, ingredient_id)

    # Check if exists
    existing = Repo.one(
      from p in BrandPackageSize,
      where: p.canonical_ingredient_id == ^ingredient_id
        and p.package_type == ^attrs.package_type
        and p.size_value == ^Decimal.new(to_string(attrs.size_value))
        and p.size_unit == ^attrs.size_unit
    )

    if existing do
      {:exists, existing}
    else
      case %BrandPackageSize{} |> BrandPackageSize.changeset(attrs) |> Repo.insert() do
        {:ok, ps} -> {:ok, ps}
        {:error, cs} -> {:error, cs}
      end
    end
  else
    {:error, :ingredient_not_found}
  end
end

IO.puts("Seeding brand package sizes...")

# ============================================================
# SODAS
# ============================================================

# Coca-Cola
coca_cola_id = get_ingredient.("coca-cola")
create_package_size.(coca_cola_id, %{package_type: "can", size_value: 12, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(coca_cola_id, %{package_type: "bottle", size_value: 20, size_unit: "oz", sort_order: 2})
create_package_size.(coca_cola_id, %{package_type: "bottle", size_value: 2, size_unit: "L", sort_order: 3})
create_package_size.(coca_cola_id, %{package_type: "can", size_value: 7.5, size_unit: "oz", sort_order: 4})
create_package_size.(coca_cola_id, %{package_type: "bottle", size_value: 16.9, size_unit: "oz", sort_order: 5})

# Sprite
sprite_id = get_ingredient.("sprite")
create_package_size.(sprite_id, %{package_type: "can", size_value: 12, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(sprite_id, %{package_type: "bottle", size_value: 20, size_unit: "oz", sort_order: 2})
create_package_size.(sprite_id, %{package_type: "bottle", size_value: 2, size_unit: "L", sort_order: 3})

# Pepsi
pepsi_id = get_ingredient.("pepsi")
create_package_size.(pepsi_id, %{package_type: "can", size_value: 12, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(pepsi_id, %{package_type: "bottle", size_value: 20, size_unit: "oz", sort_order: 2})
create_package_size.(pepsi_id, %{package_type: "bottle", size_value: 2, size_unit: "L", sort_order: 3})

# 7UP
seven_up_id = get_ingredient.("7up")
create_package_size.(seven_up_id, %{package_type: "can", size_value: 12, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(seven_up_id, %{package_type: "bottle", size_value: 20, size_unit: "oz", sort_order: 2})
create_package_size.(seven_up_id, %{package_type: "bottle", size_value: 2, size_unit: "L", sort_order: 3})

# Dr Pepper
dr_pepper_id = get_ingredient.("dr pepper")
create_package_size.(dr_pepper_id, %{package_type: "can", size_value: 12, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(dr_pepper_id, %{package_type: "bottle", size_value: 20, size_unit: "oz", sort_order: 2})
create_package_size.(dr_pepper_id, %{package_type: "bottle", size_value: 2, size_unit: "L", sort_order: 3})

# ============================================================
# HOT SAUCES
# ============================================================

# Tabasco
tabasco_id = get_ingredient.("tabasco")
create_package_size.(tabasco_id, %{package_type: "bottle", size_value: 2, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(tabasco_id, %{package_type: "bottle", size_value: 5, size_unit: "oz", sort_order: 2})
create_package_size.(tabasco_id, %{package_type: "bottle", size_value: 12, size_unit: "oz", sort_order: 3})

# Frank's RedHot
franks_id = get_ingredient.("frank's red hot")
create_package_size.(franks_id, %{package_type: "bottle", size_value: 5, size_unit: "oz", sort_order: 1})
create_package_size.(franks_id, %{package_type: "bottle", size_value: 12, size_unit: "oz", is_default: true, sort_order: 2})
create_package_size.(franks_id, %{package_type: "bottle", size_value: 32, size_unit: "oz", sort_order: 3})
create_package_size.(franks_id, %{package_type: "bottle", size_value: 64, size_unit: "oz", sort_order: 4})

# Cholula
cholula_id = get_ingredient.("cholula")
create_package_size.(cholula_id, %{package_type: "bottle", size_value: 2, size_unit: "oz", sort_order: 1})
create_package_size.(cholula_id, %{package_type: "bottle", size_value: 5, size_unit: "oz", is_default: true, sort_order: 2})
create_package_size.(cholula_id, %{package_type: "bottle", size_value: 12, size_unit: "oz", sort_order: 3})

# ============================================================
# CONDIMENTS
# ============================================================

# Heinz Ketchup
ketchup_id = get_ingredient.("heinz ketchup")
create_package_size.(ketchup_id, %{package_type: "bottle", size_value: 14, size_unit: "oz", sort_order: 1})
create_package_size.(ketchup_id, %{package_type: "bottle", size_value: 20, size_unit: "oz", is_default: true, sort_order: 2})
create_package_size.(ketchup_id, %{package_type: "bottle", size_value: 32, size_unit: "oz", sort_order: 3})
create_package_size.(ketchup_id, %{package_type: "bottle", size_value: 38, size_unit: "oz", sort_order: 4})

# French's Mustard
mustard_id = get_ingredient.("french's mustard")
create_package_size.(mustard_id, %{package_type: "bottle", size_value: 8, size_unit: "oz", sort_order: 1})
create_package_size.(mustard_id, %{package_type: "bottle", size_value: 12, size_unit: "oz", is_default: true, sort_order: 2})
create_package_size.(mustard_id, %{package_type: "bottle", size_value: 20, size_unit: "oz", sort_order: 3})

# Hellmann's Mayonnaise
mayo_id = get_ingredient.("hellmann's mayonnaise")
create_package_size.(mayo_id, %{package_type: "jar", size_value: 15, size_unit: "oz", sort_order: 1})
create_package_size.(mayo_id, %{package_type: "jar", size_value: 20, size_unit: "oz", sort_order: 2})
create_package_size.(mayo_id, %{package_type: "jar", size_value: 30, size_unit: "oz", is_default: true, sort_order: 3})
create_package_size.(mayo_id, %{package_type: "bottle", size_value: 11.5, size_unit: "oz", label: "11.5 oz squeeze bottle", sort_order: 4})
create_package_size.(mayo_id, %{package_type: "bottle", size_value: 20, size_unit: "oz", label: "20 oz squeeze bottle", sort_order: 5})

# Miracle Whip
miracle_whip_id = get_ingredient.("miracle whip")
create_package_size.(miracle_whip_id, %{package_type: "jar", size_value: 15, size_unit: "oz", sort_order: 1})
create_package_size.(miracle_whip_id, %{package_type: "jar", size_value: 30, size_unit: "oz", is_default: true, sort_order: 2})

# Hidden Valley Ranch
ranch_id = get_ingredient.("hidden valley ranch")
create_package_size.(ranch_id, %{package_type: "bottle", size_value: 16, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(ranch_id, %{package_type: "bottle", size_value: 24, size_unit: "oz", sort_order: 2})
create_package_size.(ranch_id, %{package_type: "packet", size_value: 1, size_unit: "oz", label: "1 oz dry mix packet", sort_order: 3})

# Worcestershire Sauce (Lea & Perrins)
worcestershire_id = get_ingredient.("worcestershire sauce")
create_package_size.(worcestershire_id, %{package_type: "bottle", size_value: 5, size_unit: "oz", sort_order: 1})
create_package_size.(worcestershire_id, %{package_type: "bottle", size_value: 10, size_unit: "oz", is_default: true, sort_order: 2})
create_package_size.(worcestershire_id, %{package_type: "bottle", size_value: 15, size_unit: "oz", sort_order: 3})

# ============================================================
# PEANUT BUTTER
# ============================================================

# Jif
jif_id = get_ingredient.("jif peanut butter")
create_package_size.(jif_id, %{package_type: "jar", size_value: 12, size_unit: "oz", sort_order: 1})
create_package_size.(jif_id, %{package_type: "jar", size_value: 16, size_unit: "oz", is_default: true, sort_order: 2})
create_package_size.(jif_id, %{package_type: "jar", size_value: 28, size_unit: "oz", sort_order: 3})
create_package_size.(jif_id, %{package_type: "jar", size_value: 40, size_unit: "oz", sort_order: 4})

# Skippy
skippy_id = get_ingredient.("skippy peanut butter")
create_package_size.(skippy_id, %{package_type: "jar", size_value: 16.3, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(skippy_id, %{package_type: "jar", size_value: 28, size_unit: "oz", sort_order: 2})
create_package_size.(skippy_id, %{package_type: "jar", size_value: 40, size_unit: "oz", sort_order: 3})

# ============================================================
# CHEESE PRODUCTS
# ============================================================

# Velveeta
velveeta_id = get_ingredient.("velveeta")
create_package_size.(velveeta_id, %{package_type: "box", size_value: 8, size_unit: "oz", sort_order: 1})
create_package_size.(velveeta_id, %{package_type: "box", size_value: 16, size_unit: "oz", is_default: true, sort_order: 2})
create_package_size.(velveeta_id, %{package_type: "box", size_value: 32, size_unit: "oz", sort_order: 3})

# Kraft Singles
kraft_singles_id = get_ingredient.("kraft singles")
create_package_size.(kraft_singles_id, %{package_type: "pack", size_value: 16, size_unit: "ct", is_default: true, sort_order: 1})
create_package_size.(kraft_singles_id, %{package_type: "pack", size_value: 24, size_unit: "ct", sort_order: 2})

# ============================================================
# CEREALS
# ============================================================

# Rice Chex
rice_chex_id = get_ingredient.("rice chex")
create_package_size.(rice_chex_id, %{package_type: "box", size_value: 12, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(rice_chex_id, %{package_type: "box", size_value: 18, size_unit: "oz", sort_order: 2})

# Cheerios
cheerios_id = get_ingredient.("cheerios")
create_package_size.(cheerios_id, %{package_type: "box", size_value: 8.9, size_unit: "oz", sort_order: 1})
create_package_size.(cheerios_id, %{package_type: "box", size_value: 12, size_unit: "oz", is_default: true, sort_order: 2})
create_package_size.(cheerios_id, %{package_type: "box", size_value: 18, size_unit: "oz", sort_order: 3})

# Corn Flakes
corn_flakes_id = get_ingredient.("corn flakes")
create_package_size.(corn_flakes_id, %{package_type: "box", size_value: 12, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(corn_flakes_id, %{package_type: "box", size_value: 18, size_unit: "oz", sort_order: 2})

# ============================================================
# COOKIES/CRACKERS
# ============================================================

# Ritz Crackers
ritz_id = get_ingredient.("ritz cracker")
create_package_size.(ritz_id, %{package_type: "box", size_value: 13.7, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(ritz_id, %{package_type: "sleeve", size_value: 3.4, size_unit: "oz", sort_order: 2})

# Nutter Butter
nutter_butter_id = get_ingredient.("nutter butter")
create_package_size.(nutter_butter_id, %{package_type: "pack", size_value: 16, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(nutter_butter_id, %{package_type: "pack", size_value: 10.5, size_unit: "oz", sort_order: 2})

# ============================================================
# CANDY
# ============================================================

# Butterfinger
butterfinger_id = get_ingredient.("butterfinger")
create_package_size.(butterfinger_id, %{package_type: "bar", size_value: 1.9, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(butterfinger_id, %{package_type: "bag", size_value: 10.2, size_unit: "oz", label: "10.2 oz fun size bag", sort_order: 2})
create_package_size.(butterfinger_id, %{package_type: "bar", size_value: 3.7, size_unit: "oz", label: "3.7 oz king size bar", sort_order: 3})

# Skor/Heath Bar
toffee_bar_id = get_ingredient.("chocolate toffee bar")
create_package_size.(toffee_bar_id, %{package_type: "bar", size_value: 1.4, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(toffee_bar_id, %{package_type: "bag", size_value: 8, size_unit: "oz", label: "8 oz baking bits", sort_order: 2})

# ============================================================
# MARGARINE (generic sizes since brand varies)
# ============================================================

margarine_id = get_ingredient.("margarine")
create_package_size.(margarine_id, %{package_type: "tub", size_value: 15, size_unit: "oz", is_default: true, sort_order: 1})
create_package_size.(margarine_id, %{package_type: "tub", size_value: 45, size_unit: "oz", sort_order: 2})
create_package_size.(margarine_id, %{package_type: "stick", size_value: 4, size_unit: "oz", label: "4 oz stick (1/2 cup)", sort_order: 3})

IO.puts("Done seeding brand package sizes!")

# Print summary
count = Repo.aggregate(BrandPackageSize, :count, :id)
IO.puts("Total package sizes in database: #{count}")
