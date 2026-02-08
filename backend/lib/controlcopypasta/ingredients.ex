defmodule Controlcopypasta.Ingredients do
  @moduledoc """
  Context for managing the ingredient catalog.

  This context provides functions for:
  - CRUD operations on canonical ingredients, preparations, and forms
  - Looking up ingredients by name or alias
  - Filtering ingredients by category, allergen, or dietary flags
  - Building lookup caches for efficient parsing
  """

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo

  alias Controlcopypasta.Ingredients.{
    CanonicalIngredient,
    Preparation,
    KitchenTool,
    IngredientForm,
    BrandPackageSize,
    IngredientDensity,
    IngredientNutrition,
    PendingIngredient
  }

  # =============================================================================
  # Canonical Ingredients
  # =============================================================================

  @doc """
  Returns a list of all canonical ingredients.
  """
  def list_canonical_ingredients do
    Repo.all(CanonicalIngredient)
  end

  @doc """
  Returns a list of canonical ingredients filtered by criteria.

  ## Options

  - `:category` - Filter by category
  - `:subcategory` - Filter by subcategory
  - `:tag` - Filter by tag (ingredient must have this tag)
  - `:is_allergen` - Filter by allergen status
  - `:allergen_group` - Filter by allergen group
  - `:dietary_flag` - Filter by dietary flag
  - `:search` - Search by name or alias (partial match)
  """
  def list_canonical_ingredients(opts) when is_list(opts) do
    # Preload all nutrition sources - the JSON view will select the best one
    # (primary first, then highest confidence)
    CanonicalIngredient
    |> apply_filters(opts)
    |> preload(:nutrition_sources)
    |> Repo.all()
  end

  defp apply_filters(query, []), do: query

  defp apply_filters(query, [{:category, category} | rest]) when is_binary(category) do
    query
    |> where([i], i.category == ^category)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:subcategory, subcategory} | rest]) when is_binary(subcategory) do
    query
    |> where([i], i.subcategory == ^subcategory)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:tag, tag} | rest]) when is_binary(tag) do
    query
    |> where([i], ^tag in i.tags)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:is_allergen, is_allergen} | rest]) when is_boolean(is_allergen) do
    query
    |> where([i], i.is_allergen == ^is_allergen)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:is_branded, is_branded} | rest]) when is_boolean(is_branded) do
    query
    |> where([i], i.is_branded == ^is_branded)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:parent_company, company} | rest]) when is_binary(company) do
    query
    |> where([i], i.parent_company == ^company)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:allergen_group, group} | rest]) when is_binary(group) do
    query
    |> where([i], ^group in i.allergen_groups)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:animal_type, animal_type} | rest]) when is_binary(animal_type) do
    query
    |> where([i], i.animal_type == ^animal_type)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:missing_animal_type, true} | rest]) do
    query
    |> where([i], i.category == "protein" and is_nil(i.animal_type))
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:dietary_flag, flag} | rest]) when is_binary(flag) do
    query
    |> where([i], ^flag in i.dietary_flags)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:search, search} | rest]) when is_binary(search) do
    pattern = "%#{search}%"

    query
    |> where(
      [i],
      ilike(i.name, ^pattern) or
        ilike(i.display_name, ^pattern) or
        fragment("EXISTS (SELECT 1 FROM unnest(?) alias WHERE alias ILIKE ?)", i.aliases, ^pattern)
    )
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:order_by, :popularity} | rest]) do
    query
    |> order_by([i], desc: i.usage_count, asc: i.name)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [{:order_by, :name} | rest]) do
    query
    |> order_by([i], asc: i.name)
    |> apply_filters(rest)
  end

  defp apply_filters(query, [_ | rest]), do: apply_filters(query, rest)

  @doc """
  Gets a single canonical ingredient by ID.
  """
  def get_canonical_ingredient(id) do
    Repo.get(CanonicalIngredient, id)
  end

  @doc """
  Gets a canonical ingredient by ID, raising if not found.
  """
  def get_canonical_ingredient!(id) do
    Repo.get!(CanonicalIngredient, id)
  end

  @doc """
  Gets a canonical ingredient by name (exact match, case-insensitive).
  """
  def get_canonical_ingredient_by_name(name) when is_binary(name) do
    normalized = String.downcase(String.trim(name))
    Repo.get_by(CanonicalIngredient, name: normalized)
  end

  @doc """
  Finds a canonical ingredient by name or alias.

  Searches in order:
  1. Exact name match
  2. Alias match

  Returns `{:ok, ingredient}` or `{:error, :not_found}`.
  """
  def find_canonical_ingredient(name) when is_binary(name) do
    normalized = String.downcase(String.trim(name))

    # Try exact name match first
    case get_canonical_ingredient_by_name(normalized) do
      %CanonicalIngredient{} = ingredient ->
        {:ok, ingredient}

      nil ->
        # Try alias match
        query =
          from(i in CanonicalIngredient,
            where: ^normalized in i.aliases,
            limit: 1
          )

        case Repo.one(query) do
          %CanonicalIngredient{} = ingredient -> {:ok, ingredient}
          nil -> {:error, :not_found}
        end
    end
  end

  @doc """
  Creates a canonical ingredient.

  Automatically queues density enrichment to fetch density data from APIs
  (disabled in test environment to avoid blocking tests).
  """
  def create_canonical_ingredient(attrs \\ %{}) do
    result =
      %CanonicalIngredient{}
      |> CanonicalIngredient.changeset(attrs)
      |> Repo.insert()

    # Queue density enrichment for new ingredient (skip in test environment)
    case result do
      {:ok, ingredient} ->
        unless Application.get_env(:controlcopypasta, :env) == :test do
          Controlcopypasta.Nutrition.DensityEnrichmentWorker.enqueue(ingredient.id)
        end

        {:ok, ingredient}

      error ->
        error
    end
  end

  @doc """
  Updates a canonical ingredient.
  """
  def update_canonical_ingredient(%CanonicalIngredient{} = ingredient, attrs) do
    ingredient
    |> CanonicalIngredient.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a canonical ingredient.
  """
  def delete_canonical_ingredient(%CanonicalIngredient{} = ingredient) do
    Repo.delete(ingredient)
  end

  @doc """
  Returns a changeset for tracking canonical ingredient changes.
  """
  def change_canonical_ingredient(%CanonicalIngredient{} = ingredient, attrs \\ %{}) do
    CanonicalIngredient.changeset(ingredient, attrs)
  end

  # =============================================================================
  # Preparations
  # =============================================================================

  @doc """
  Returns a list of all preparations.

  Accepts optional filters:
  - `{:category, category}` — filter by category
  - `{:search, term}` — search by name or display_name
  - `{:order_by, field}` — order by field (default: :name)
  """
  def list_preparations(filters \\ []) do
    Preparation
    |> apply_preparation_filters(filters)
    |> Repo.all()
  end

  defp apply_preparation_filters(query, []), do: query

  defp apply_preparation_filters(query, [{:category, category} | rest]) when is_binary(category) and category != "" do
    query
    |> where([p], p.category == ^category)
    |> apply_preparation_filters(rest)
  end

  defp apply_preparation_filters(query, [{:search, term} | rest]) when is_binary(term) and term != "" do
    like_term = "%#{term}%"

    query
    |> where([p], ilike(p.name, ^like_term) or ilike(p.display_name, ^like_term))
    |> apply_preparation_filters(rest)
  end

  defp apply_preparation_filters(query, [{:order_by, :name} | rest]) do
    query
    |> order_by([p], p.name)
    |> apply_preparation_filters(rest)
  end

  defp apply_preparation_filters(query, [_ | rest]) do
    apply_preparation_filters(query, rest)
  end

  @doc """
  Returns preparations filtered by category.
  """
  def list_preparations_by_category(category) when is_binary(category) do
    Preparation
    |> where([p], p.category == ^category)
    |> Repo.all()
  end

  @doc """
  Gets a single preparation by ID.
  """
  def get_preparation(id) do
    Repo.get(Preparation, id)
  end

  @doc """
  Gets a preparation by ID, raising if not found.
  """
  def get_preparation!(id) do
    Repo.get!(Preparation, id)
  end

  @doc """
  Gets a preparation by name (exact match, case-insensitive).
  """
  def get_preparation_by_name(name) when is_binary(name) do
    normalized = String.downcase(String.trim(name))
    Repo.get_by(Preparation, name: normalized)
  end

  @doc """
  Finds a preparation by name or alias.
  """
  def find_preparation(name) when is_binary(name) do
    normalized = String.downcase(String.trim(name))

    case get_preparation_by_name(normalized) do
      %Preparation{} = prep ->
        {:ok, prep}

      nil ->
        query =
          from(p in Preparation,
            where: ^normalized in p.aliases,
            limit: 1
          )

        case Repo.one(query) do
          %Preparation{} = prep -> {:ok, prep}
          nil -> {:error, :not_found}
        end
    end
  end

  @doc """
  Creates a preparation.
  """
  def create_preparation(attrs \\ %{}) do
    %Preparation{}
    |> Preparation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a preparation.
  """
  def update_preparation(%Preparation{} = preparation, attrs) do
    preparation
    |> Preparation.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a preparation.
  """
  def delete_preparation(%Preparation{} = preparation) do
    Repo.delete(preparation)
  end

  # =============================================================================
  # Kitchen Tools
  # =============================================================================

  @doc """
  Returns a list of all kitchen tools.

  Accepts optional filters:
  - `{:category, category}` — filter by category
  - `{:search, term}` — search by name or display_name
  - `{:order_by, field}` — order by field (default: :name)
  """
  def list_kitchen_tools(filters \\ []) do
    KitchenTool
    |> apply_kitchen_tool_filters(filters)
    |> Repo.all()
  end

  defp apply_kitchen_tool_filters(query, []), do: query

  defp apply_kitchen_tool_filters(query, [{:category, category} | rest]) when is_binary(category) and category != "" do
    query
    |> where([t], t.category == ^category)
    |> apply_kitchen_tool_filters(rest)
  end

  defp apply_kitchen_tool_filters(query, [{:search, term} | rest]) when is_binary(term) and term != "" do
    like_term = "%#{term}%"

    query
    |> where([t], ilike(t.name, ^like_term) or ilike(t.display_name, ^like_term))
    |> apply_kitchen_tool_filters(rest)
  end

  defp apply_kitchen_tool_filters(query, [{:order_by, :name} | rest]) do
    query
    |> order_by([t], t.name)
    |> apply_kitchen_tool_filters(rest)
  end

  defp apply_kitchen_tool_filters(query, [_ | rest]) do
    apply_kitchen_tool_filters(query, rest)
  end

  @doc """
  Gets a single kitchen tool by ID.
  """
  def get_kitchen_tool(id) do
    Repo.get(KitchenTool, id)
  end

  @doc """
  Gets a kitchen tool by ID, raising if not found.
  """
  def get_kitchen_tool!(id) do
    Repo.get!(KitchenTool, id)
  end

  @doc """
  Gets a kitchen tool by name (exact match, case-insensitive).
  """
  def get_kitchen_tool_by_name(name) when is_binary(name) do
    normalized = String.downcase(String.trim(name))
    Repo.get_by(KitchenTool, name: normalized)
  end

  @doc """
  Creates a kitchen tool.
  """
  def create_kitchen_tool(attrs \\ %{}) do
    %KitchenTool{}
    |> KitchenTool.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a kitchen tool.
  """
  def update_kitchen_tool(%KitchenTool{} = tool, attrs) do
    tool
    |> KitchenTool.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a kitchen tool.
  """
  def delete_kitchen_tool(%KitchenTool{} = tool) do
    Repo.delete(tool)
  end

  # =============================================================================
  # Ingredient Forms
  # =============================================================================

  @doc """
  Returns a list of all ingredient forms.
  """
  def list_ingredient_forms do
    Repo.all(IngredientForm)
  end

  @doc """
  Returns forms for a specific canonical ingredient.
  """
  def list_forms_for_ingredient(canonical_ingredient_id) do
    IngredientForm
    |> where([f], f.canonical_ingredient_id == ^canonical_ingredient_id)
    |> Repo.all()
  end

  @doc """
  Gets a single ingredient form by ID.
  """
  def get_ingredient_form(id) do
    Repo.get(IngredientForm, id)
  end

  @doc """
  Gets an ingredient form by ingredient ID and form name.
  """
  def get_ingredient_form(canonical_ingredient_id, form_name) do
    normalized = String.downcase(String.trim(form_name))

    Repo.get_by(IngredientForm,
      canonical_ingredient_id: canonical_ingredient_id,
      form_name: normalized
    )
  end

  @doc """
  Creates an ingredient form.
  """
  def create_ingredient_form(attrs \\ %{}) do
    %IngredientForm{}
    |> IngredientForm.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an ingredient form.
  """
  def update_ingredient_form(%IngredientForm{} = form, attrs) do
    form
    |> IngredientForm.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an ingredient form.
  """
  def delete_ingredient_form(%IngredientForm{} = form) do
    Repo.delete(form)
  end

  # =============================================================================
  # Lookup Caches
  # =============================================================================

  @doc """
  Builds a lookup map from all ingredient names and aliases to their canonical info.

  Returns a map where keys are lowercase names/aliases and values are
  `{canonical_name, canonical_id}` tuples.

  This is useful for efficient ingredient matching during parsing.
  """
  def build_ingredient_lookup do
    CanonicalIngredient
    |> select([i], {i.id, i.name, i.aliases})
    |> Repo.all()
    |> Enum.flat_map(fn {id, name, aliases} ->
      # Map both the canonical name and all aliases to {canonical_name, id}
      # Lowercase keys for case-insensitive matching (Matcher normalizes input to lowercase)
      [{String.downcase(name), {name, id}} |
       Enum.map(aliases || [], &{String.downcase(&1), {name, id}})]
    end)
    |> Map.new()
  end

  @doc """
  Builds a lookup map with matching rules for ingredient scoring.

  Returns a map where keys are lowercase names/aliases and values are
  `{canonical_name, canonical_id, matching_rules}` tuples.

  Only loads matching_rules for top N ingredients by usage_count (default 300).
  Long tail ingredients have `matching_rules: nil`.

  ## Options

  - `:top_n` - Number of top ingredients to load rules for (default: 300)

  ## Examples

      iex> lookup = build_ingredient_lookup_with_rules()
      iex> lookup["chicken breast"]
      {"chicken breast", "some-uuid", %{"boost_words" => ["boneless"], ...}}

      iex> lookup["obscure ingredient"]
      {"obscure ingredient", "some-other-uuid", nil}
  """
  def build_ingredient_lookup_with_rules(opts \\ []) do
    top_n = Keyword.get(opts, :top_n, 300)

    # Get top N ingredient IDs by usage
    top_ids =
      from(i in CanonicalIngredient,
        order_by: [desc: i.usage_count],
        limit: ^top_n,
        select: i.id
      )
      |> Repo.all()
      |> MapSet.new()

    # Load all ingredients with matching_rules for top N only
    CanonicalIngredient
    |> select([i], {i.id, i.name, i.aliases, i.matching_rules})
    |> Repo.all()
    |> Enum.flat_map(fn {id, name, aliases, rules} ->
      # Only include rules for top N ingredients
      effective_rules = if MapSet.member?(top_ids, id), do: rules, else: nil

      # Map both the canonical name and all aliases to {canonical_name, id, rules}
      # Lowercase keys for case-insensitive matching
      entries = [{String.downcase(name), {name, id, effective_rules}}]

      alias_entries =
        (aliases || [])
        |> Enum.map(&{String.downcase(&1), {name, id, effective_rules}})

      entries ++ alias_entries
    end)
    |> Map.new()
  end

  @doc """
  Builds a lookup map from all preparation names and aliases to their info.

  Returns a map where keys are lowercase names/aliases and values are
  `{canonical_name, id, metadata}` tuples including verb, category, tool, and timing.
  """
  def build_preparation_lookup do
    Preparation
    |> select([p], {p.id, p.name, p.aliases, p.verb, p.category, p.metadata})
    |> Repo.all()
    |> Enum.flat_map(fn {id, name, aliases, verb, category, metadata} ->
      meta = %{verb: verb, category: category, metadata: metadata}
      [{name, {name, id, meta}} | Enum.map(aliases || [], &{&1, {name, id, meta}})]
    end)
    |> Map.new()
  end

  @doc """
  Builds a normalizer lookup map from canonical_ingredients with similarity_name.

  Returns a map where keys are variant names (ingredient names + aliases) and
  values are the canonical form (similarity_name or ingredient name).
  """
  def build_normalizer_lookup do
    CanonicalIngredient
    |> select([ci], {ci.name, ci.aliases, ci.similarity_name})
    |> Repo.all()
    |> Enum.flat_map(fn {name, aliases, similarity_name} ->
      # If ingredient has a similarity_name, map its name to that
      base = if similarity_name, do: [{name, similarity_name}], else: []

      # Map all aliases to the similarity_name (if set) or the ingredient name
      alias_entries =
        (aliases || [])
        |> Enum.map(fn alias_name -> {alias_name, similarity_name || name} end)

      base ++ alias_entries
    end)
    |> Map.new()
  end

  @doc """
  Refreshes the parser cache (preparations + normalizer) from the database.
  Call this after admin edits to preparations or canonical ingredients.
  """
  def refresh_parser_cache! do
    Controlcopypasta.Ingredients.ParserCache.refresh!()
  end

  @doc """
  Returns ingredient names that contain an allergen from the given groups.
  """
  def get_allergen_ingredients(allergen_groups) when is_list(allergen_groups) do
    CanonicalIngredient
    |> where([i], fragment("? && ?", i.allergen_groups, ^allergen_groups))
    |> select([i], i.name)
    |> Repo.all()
  end

  @doc """
  Returns a MapSet of canonical ingredient IDs for ingredients in the given categories.
  """
  def list_canonical_ids_by_categories(categories) when is_list(categories) do
    CanonicalIngredient
    |> where([i], i.category in ^categories)
    |> select([i], i.id)
    |> Repo.all()
    |> MapSet.new()
  end

  @doc """
  Returns a MapSet of canonical ingredient IDs for ingredients in the given allergen groups.
  """
  def list_canonical_ids_by_allergen_groups(allergen_groups) when is_list(allergen_groups) do
    CanonicalIngredient
    |> where([i], fragment("? && ?", i.allergen_groups, ^allergen_groups))
    |> select([i], i.id)
    |> Repo.all()
    |> MapSet.new()
  end

  @doc """
  Returns a MapSet of canonical ingredient IDs for ingredients of the given animal types.
  """
  def list_canonical_ids_by_animal_types(animal_types) when is_list(animal_types) do
    CanonicalIngredient
    |> where([i], i.animal_type in ^animal_types)
    |> select([i], i.id)
    |> Repo.all()
    |> MapSet.new()
  end

  @doc """
  Returns ingredients that match the given dietary flag.
  """
  def get_dietary_ingredients(flag) when is_binary(flag) do
    CanonicalIngredient
    |> where([i], ^flag in i.dietary_flags)
    |> select([i], {i.name, i.display_name})
    |> Repo.all()
  end

  @doc """
  Finds ingredients related by tags.

  Given an ingredient, returns other ingredients that share at least one tag.
  """
  def find_related_by_tags(%CanonicalIngredient{id: id, tags: tags}) when is_list(tags) do
    CanonicalIngredient
    |> where([i], i.id != ^id)
    |> where([i], fragment("? && ?::varchar[]", i.tags, ^tags))
    |> Repo.all()
  end

  def find_related_by_tags(_), do: []

  @doc """
  Bulk inserts canonical ingredients.

  Useful for seeding data efficiently.
  """
  def bulk_insert_canonical_ingredients(ingredients) when is_list(ingredients) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      Enum.map(ingredients, fn attrs ->
        attrs
        |> Map.put(:id, Ecto.UUID.generate())
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
        |> ensure_defaults()
      end)

    Repo.insert_all(CanonicalIngredient, entries,
      on_conflict: :nothing,
      conflict_target: :name
    )
  end

  @doc """
  Bulk inserts preparations.
  """
  def bulk_insert_preparations(preparations) when is_list(preparations) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      Enum.map(preparations, fn attrs ->
        attrs
        |> Map.put(:id, Ecto.UUID.generate())
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
        |> Map.put_new(:aliases, [])
      end)

    Repo.insert_all(Preparation, entries,
      on_conflict: :nothing,
      conflict_target: :name
    )
  end

  defp ensure_defaults(attrs) do
    attrs
    |> Map.put_new(:tags, [])
    |> Map.put_new(:is_allergen, false)
    |> Map.put_new(:allergen_groups, [])
    |> Map.put_new(:dietary_flags, [])
    |> Map.put_new(:aliases, [])
  end

  # =============================================================================
  # Brand Package Sizes
  # =============================================================================

  @doc """
  Returns all package sizes for a canonical ingredient.
  """
  def list_package_sizes(canonical_ingredient_id) do
    BrandPackageSize
    |> where([p], p.canonical_ingredient_id == ^canonical_ingredient_id)
    |> order_by([p], [asc: p.sort_order, asc: p.size_value])
    |> Repo.all()
  end

  @doc """
  Gets the default package size for an ingredient.
  """
  def get_default_package_size(canonical_ingredient_id) do
    BrandPackageSize
    |> where([p], p.canonical_ingredient_id == ^canonical_ingredient_id and p.is_default == true)
    |> Repo.one()
  end

  @doc """
  Creates a brand package size.
  """
  def create_package_size(attrs \\ %{}) do
    %BrandPackageSize{}
    |> BrandPackageSize.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a brand package size.
  """
  def update_package_size(%BrandPackageSize{} = package_size, attrs) do
    package_size
    |> BrandPackageSize.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a brand package size.
  """
  def delete_package_size(%BrandPackageSize{} = package_size) do
    Repo.delete(package_size)
  end

  @doc """
  Calculates scaled quantity with package size context.

  Given an ingredient, quantity, unit, and scale factor, returns
  scaling suggestions based on available package sizes.

  ## Examples

      iex> scale_with_package_context(coca_cola_id, 1, "can", 2.5)
      %{
        scaled_quantity: 2.5,
        scaled_unit: "can",
        total_volume: %{value: 30, unit: "oz"},
        package_suggestion: "Buy 3 cans (36 oz total, 6 oz extra)",
        available_packages: [%{type: "can", size: "12 oz", count_needed: 3}]
      }
  """
  def scale_with_package_context(canonical_ingredient_id, quantity, unit, scale_factor) do
    scaled_qty = quantity * scale_factor
    packages = list_package_sizes(canonical_ingredient_id)
    default_package = get_default_package_size(canonical_ingredient_id)

    cond do
      # No package info available
      Enum.empty?(packages) ->
        %{
          scaled_quantity: scaled_qty,
          scaled_unit: unit,
          total_volume: nil,
          package_suggestion: nil,
          available_packages: []
        }

      # Has package sizes - calculate suggestions
      true ->
        # Find matching package type or use default
        matching_package = find_matching_package(packages, unit) || default_package || hd(packages)

        if matching_package do
          calculate_package_suggestion(scaled_qty, unit, matching_package, packages)
        else
          %{
            scaled_quantity: scaled_qty,
            scaled_unit: unit,
            total_volume: nil,
            package_suggestion: nil,
            available_packages: format_available_packages(packages)
          }
        end
    end
  end

  defp find_matching_package(packages, unit) do
    # Try to find a package that matches the unit (e.g., "can" -> package_type: "can")
    normalized_unit = String.downcase(unit || "")
    Enum.find(packages, fn p ->
      String.downcase(p.package_type) == normalized_unit ||
        String.downcase(p.package_type) == String.replace(normalized_unit, ~r/s$/, "")
    end)
  end

  defp calculate_package_suggestion(scaled_qty, unit, package, all_packages) do
    size_value = Decimal.to_float(package.size_value)
    total_volume_needed = scaled_qty * size_value

    # Calculate how many packages to buy (round up)
    packages_needed = Float.ceil(scaled_qty)
    total_volume_bought = packages_needed * size_value
    extra_volume = total_volume_bought - total_volume_needed

    suggestion = if extra_volume > 0 do
      "Buy #{format_count(packages_needed)} #{pluralize(package.package_type, packages_needed)} " <>
        "(#{format_volume(total_volume_bought, package.size_unit)} total, " <>
        "#{format_volume(extra_volume, package.size_unit)} extra)"
    else
      "Buy #{format_count(packages_needed)} #{pluralize(package.package_type, packages_needed)}"
    end

    %{
      scaled_quantity: scaled_qty,
      scaled_unit: unit,
      total_volume: %{value: total_volume_needed, unit: package.size_unit},
      package_suggestion: suggestion,
      packages_to_buy: trunc(packages_needed),
      package_size: package.label,
      available_packages: format_available_packages(all_packages)
    }
  end

  defp format_available_packages(packages) do
    Enum.map(packages, fn p ->
      %{
        type: p.package_type,
        size_value: Decimal.to_float(p.size_value),
        size_unit: p.size_unit,
        label: p.label,
        is_default: p.is_default
      }
    end)
  end

  defp format_count(count) when count == 1.0, do: "1"
  defp format_count(count), do: Integer.to_string(trunc(count))

  defp format_volume(volume, unit) do
    if volume == trunc(volume) do
      "#{trunc(volume)} #{unit}"
    else
      "#{Float.round(volume, 1)} #{unit}"
    end
  end

  defp pluralize(word, count) when count == 1.0, do: word
  defp pluralize(word, _count), do: word <> "s"

  # =============================================================================
  # Nutrition
  # =============================================================================

  alias Controlcopypasta.Ingredients.IngredientNutrition

  @doc """
  Gets the primary (most trusted) nutrition data for an ingredient.

  First checks for a record marked as `is_primary`, then falls back to
  the highest-trust source available.
  """
  def get_nutrition(canonical_ingredient_id) do
    # First try to get the primary record
    primary_query =
      from(n in IngredientNutrition,
        where: n.canonical_ingredient_id == ^canonical_ingredient_id and n.is_primary == true,
        limit: 1
      )

    case Repo.one(primary_query) do
      %IngredientNutrition{} = nutrition ->
        {:ok, nutrition}

      nil ->
        # Fall back to highest-trust source, using confidence as tiebreaker
        fallback_query =
          from(n in IngredientNutrition,
            where: n.canonical_ingredient_id == ^canonical_ingredient_id,
            order_by: [
              asc: fragment("array_position(ARRAY['usda','manual','fatsecret','open_food_facts','nutritionix','estimated']::nutrition_source[], ?)", n.source),
              desc: n.confidence
            ],
            limit: 1
          )

        case Repo.one(fallback_query) do
          %IngredientNutrition{} = nutrition -> {:ok, nutrition}
          nil -> {:error, :not_found}
        end
    end
  end

  @doc """
  Lists all nutrition sources for an ingredient.
  """
  def list_nutrition_sources(canonical_ingredient_id) do
    from(n in IngredientNutrition,
      where: n.canonical_ingredient_id == ^canonical_ingredient_id,
      order_by: [
        asc: fragment("array_position(ARRAY['usda','manual','fatsecret','open_food_facts','nutritionix','estimated']::nutrition_source[], ?)", n.source),
        desc: n.confidence
      ]
    )
    |> Repo.all()
  end

  @doc """
  Creates nutrition data for an ingredient.

  Automatically calculates confidence score if not provided.
  """
  def create_nutrition(attrs) do
    %IngredientNutrition{}
    |> IngredientNutrition.changeset(attrs)
    |> maybe_calculate_confidence()
    |> Repo.insert()
  end

  # Calculate confidence if not already set
  defp maybe_calculate_confidence(changeset) do
    if Ecto.Changeset.get_field(changeset, :confidence) do
      changeset
    else
      IngredientNutrition.with_calculated_confidence(changeset)
    end
  end

  @doc """
  Updates nutrition data.

  Recalculates confidence score if nutrient fields change.
  """
  def update_nutrition(%IngredientNutrition{} = nutrition, attrs) do
    nutrition
    |> IngredientNutrition.changeset(attrs)
    |> maybe_recalculate_confidence()
    |> Repo.update()
  end

  # Recalculate confidence if nutrient or source fields changed
  defp maybe_recalculate_confidence(changeset) do
    nutrient_fields = IngredientNutrition.macro_fields() ++ [:source, :verified_at, :last_checked_at]

    has_nutrient_changes = Enum.any?(nutrient_fields, fn field ->
      Ecto.Changeset.get_change(changeset, field) != nil
    end)

    if has_nutrient_changes do
      IngredientNutrition.with_calculated_confidence(changeset)
    else
      changeset
    end
  end

  @doc """
  Sets a nutrition record as the primary source for its ingredient.

  Unsets any existing primary for that ingredient first.
  """
  def set_primary_nutrition(%IngredientNutrition{} = nutrition) do
    Repo.transaction(fn ->
      # Unset existing primary
      from(n in IngredientNutrition,
        where: n.canonical_ingredient_id == ^nutrition.canonical_ingredient_id and n.is_primary == true
      )
      |> Repo.update_all(set: [is_primary: false])

      # Set new primary
      nutrition
      |> IngredientNutrition.changeset(%{is_primary: true})
      |> Repo.update!()
    end)
  end

  @doc """
  Deletes nutrition data.
  """
  def delete_nutrition(%IngredientNutrition{} = nutrition) do
    Repo.delete(nutrition)
  end

  @doc """
  Upserts nutrition data for an ingredient (insert or update on conflict).

  Conflicts on `(canonical_ingredient_id, source, source_id)`.
  On conflict, replaces nutrient values and metadata.
  """
  def upsert_nutrition(attrs) do
    %IngredientNutrition{}
    |> IngredientNutrition.changeset(attrs)
    |> maybe_calculate_confidence()
    |> Repo.insert(
      on_conflict: {:replace, [
        :source_name, :source_url, :serving_size_value, :serving_size_unit, :serving_description,
        :calories, :protein_g, :fat_total_g, :fat_saturated_g, :fat_trans_g,
        :fat_polyunsaturated_g, :fat_monounsaturated_g, :carbohydrates_g,
        :fiber_g, :sugar_g, :sugar_added_g,
        :sodium_mg, :potassium_mg, :calcium_mg, :iron_mg, :magnesium_mg,
        :phosphorus_mg, :zinc_mg,
        :vitamin_a_mcg, :vitamin_c_mg, :vitamin_d_mcg, :vitamin_e_mg, :vitamin_k_mcg,
        :vitamin_b6_mg, :vitamin_b12_mcg, :folate_mcg, :thiamin_mg, :riboflavin_mg, :niacin_mg,
        :cholesterol_mg, :water_g,
        :confidence, :confidence_factors, :retrieved_at, :last_checked_at,
        :updated_at
      ]},
      conflict_target: [:canonical_ingredient_id, :source, :source_id]
    )
  end

  @doc """
  Gets nutrition data for an ingredient by source.

  Returns the highest-confidence record for that source.
  """
  def get_nutrition_by_source(canonical_ingredient_id, source) when is_atom(source) do
    from(n in IngredientNutrition,
      where: n.canonical_ingredient_id == ^canonical_ingredient_id and n.source == ^source,
      order_by: [desc: n.confidence],
      limit: 1
    )
    |> Repo.one()
  end

  @doc """
  Checks if an ingredient has any nutrition data.
  """
  def has_nutrition?(canonical_ingredient_id) do
    from(n in IngredientNutrition,
      where: n.canonical_ingredient_id == ^canonical_ingredient_id,
      select: count(n.id)
    )
    |> Repo.one!() > 0
  end

  @doc """
  Counts ingredients with and without nutrition data.
  """
  def nutrition_coverage_stats do
    total = Repo.aggregate(CanonicalIngredient, :count, :id)

    with_nutrition =
      from(ci in CanonicalIngredient,
        join: n in IngredientNutrition,
        on: n.canonical_ingredient_id == ci.id,
        select: count(ci.id, :distinct)
      )
      |> Repo.one!()

    %{
      total_ingredients: total,
      with_nutrition: with_nutrition,
      without_nutrition: total - with_nutrition,
      coverage_percent: if(total > 0, do: Float.round(with_nutrition / total * 100, 1), else: 0)
    }
  end

  @doc """
  Lists ingredients that don't have nutrition data.
  """
  def list_ingredients_without_nutrition do
    subquery = from(n in IngredientNutrition, select: n.canonical_ingredient_id)

    from(ci in CanonicalIngredient,
      where: ci.id not in subquery(subquery),
      order_by: ci.name
    )
    |> Repo.all()
  end

  @doc """
  Lists branded ingredients that don't have nutrition data.
  """
  def list_branded_ingredients_without_nutrition do
    subquery = from(n in IngredientNutrition, select: n.canonical_ingredient_id)

    from(ci in CanonicalIngredient,
      where: ci.id not in subquery(subquery),
      where: ci.is_branded == true,
      order_by: ci.name
    )
    |> Repo.all()
  end

  # Helper to find ingredient match from word list using n-gram lookups
  defp find_ingredient_match(words, name_to_id) when length(words) >= 3 do
    # Try 3-word combinations first
    words
    |> Enum.chunk_every(3, 1, :discard)
    |> Enum.find_value(fn [w1, w2, w3] ->
      Map.get(name_to_id, "#{w1} #{w2} #{w3}")
    end)
    |> case do
      nil -> find_ingredient_match_2(words, name_to_id)
      id -> id
    end
  end

  defp find_ingredient_match(words, name_to_id), do: find_ingredient_match_2(words, name_to_id)

  defp find_ingredient_match_2(words, name_to_id) when length(words) >= 2 do
    # Try 2-word combinations
    words
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.find_value(fn [w1, w2] ->
      Map.get(name_to_id, "#{w1} #{w2}")
    end)
    |> case do
      nil -> find_ingredient_match_1(words, name_to_id)
      id -> id
    end
  end

  defp find_ingredient_match_2(words, name_to_id), do: find_ingredient_match_1(words, name_to_id)

  defp find_ingredient_match_1(words, name_to_id) do
    # Try single words
    Enum.find_value(words, &Map.get(name_to_id, &1))
  end

  @doc """
  Lists ingredients without images, ordered by usage in recipes (most used first).

  This parses all recipe ingredients, matches them to canonical ingredients,
  and returns those without images ordered by frequency of use.
  """
  def list_ingredients_without_images_by_usage(limit \\ nil) do
    alias Controlcopypasta.Recipes.Recipe

    # Get all canonical ingredients without images
    ingredients_without_images =
      from(ci in CanonicalIngredient,
        where: is_nil(ci.image_url),
        select: {ci.id, ci.name, ci.aliases}
      )
      |> Repo.all()

    # Build a map of ingredient name -> id for O(1) lookups
    name_to_id =
      ingredients_without_images
      |> Enum.flat_map(fn {id, name, aliases} ->
        all_names = [name | aliases || []]
        Enum.map(all_names, &{String.downcase(&1), id})
      end)
      |> Map.new()

    # Count usage by extracting words from ingredient text and doing map lookups
    # This is a heuristic - we check 1-word, 2-word, and 3-word combinations
    usage_counts =
      from(r in Recipe, select: r.ingredients)
      |> Repo.all()
      |> List.flatten()
      |> Enum.reduce(%{}, fn %{"text" => text}, acc ->
        # Extract words, removing common filler words and punctuation
        words =
          text
          |> String.downcase()
          |> String.replace(~r/[^\w\s]/, " ")
          |> String.split(~r/\s+/, trim: true)
          |> Enum.reject(&(&1 in ~w(a an the of to for with and or in on at cup cups tablespoon tablespoons teaspoon teaspoons oz ounce ounces lb lbs pound pounds g gram grams kg ml l)))

        # Try matching 3-word, 2-word, and 1-word combinations
        matched_id = find_ingredient_match(words, name_to_id)

        case matched_id do
          nil -> acc
          id -> Map.update(acc, id, 1, &(&1 + 1))
        end
      end)

    # Get the IDs without images, sorted by usage (most used first)
    ids_by_usage =
      ingredients_without_images
      |> Enum.map(fn {id, _, _} -> {id, Map.get(usage_counts, id, 0)} end)
      |> Enum.sort_by(fn {_, count} -> -count end)
      |> Enum.map(fn {id, _} -> id end)

    ids_by_usage = if limit, do: Enum.take(ids_by_usage, limit), else: ids_by_usage

    # Fetch full records in usage order
    ingredients_map =
      from(ci in CanonicalIngredient, where: ci.id in ^ids_by_usage)
      |> Repo.all()
      |> Map.new(&{&1.id, &1})

    Enum.map(ids_by_usage, &Map.get(ingredients_map, &1))
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Updates usage_count for all canonical ingredients based on recipe usage.

  This function calculates how many times each ingredient appears across all recipes
  and updates the cached usage_count field. Run this periodically (e.g., daily).

  Returns `{:ok, %{updated: count}}` on success.
  """
  def update_all_usage_counts do
    require Logger
    alias Controlcopypasta.Recipes.Recipe

    Logger.info("Calculating ingredient usage counts...")

    # Get all canonical ingredients
    all_ingredients =
      from(ci in CanonicalIngredient, select: {ci.id, ci.name, ci.aliases})
      |> Repo.all()

    # Build name -> id lookup map
    name_to_id =
      all_ingredients
      |> Enum.flat_map(fn {id, name, aliases} ->
        all_names = [name | aliases || []]
        Enum.map(all_names, &{String.downcase(&1), id})
      end)
      |> Map.new()

    # Count usage in all recipes
    usage_counts =
      from(r in Recipe, select: r.ingredients)
      |> Repo.all()
      |> List.flatten()
      |> Enum.reduce(%{}, fn %{"text" => text}, acc ->
        words =
          text
          |> String.downcase()
          |> String.replace(~r/[^\w\s]/, " ")
          |> String.split(~r/\s+/, trim: true)
          |> Enum.reject(&(&1 in ~w(a an the of to for with and or in on at cup cups tablespoon tablespoons teaspoon teaspoons oz ounce ounces lb lbs pound pounds g gram grams kg ml l)))

        case find_ingredient_match(words, name_to_id) do
          nil -> acc
          id -> Map.update(acc, id, 1, &(&1 + 1))
        end
      end)

    Logger.info("Updating usage counts for #{map_size(usage_counts)} ingredients...")

    # Update all ingredients with their counts
    updated_count =
      Enum.reduce(all_ingredients, 0, fn {id, _, _}, count ->
        usage = Map.get(usage_counts, id, 0)

        from(ci in CanonicalIngredient, where: ci.id == ^id)
        |> Repo.update_all(set: [usage_count: usage])

        count + 1
      end)

    Logger.info("Updated #{updated_count} ingredient usage counts")
    {:ok, %{updated: updated_count}}
  end

  @doc """
  Gets ingredients ordered by popularity (usage_count).

  Uses cached usage_count field for fast queries.

  ## Options

  - `:limit` - Maximum number of ingredients to return
  - `:offset` - Number of ingredients to skip
  """
  def list_by_popularity(opts \\ []) do
    limit = Keyword.get(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)

    query =
      from(ci in CanonicalIngredient,
        order_by: [desc: ci.usage_count, asc: ci.name],
        offset: ^offset
      )

    query = if limit, do: limit(query, ^limit), else: query

    Repo.all(query)
  end

  @doc """
  Returns the usage count for an ingredient by ID or name.

  Useful for parser confidence scoring - more common ingredients
  should have higher confidence when matched.
  """
  def get_usage_count(ingredient_id) when is_binary(ingredient_id) do
    case Repo.get(CanonicalIngredient, ingredient_id) do
      nil -> 0
      ingredient -> ingredient.usage_count || 0
    end
  end

  def get_usage_count_by_name(name) when is_binary(name) do
    case find_canonical_ingredient(name) do
      {:ok, ingredient} -> ingredient.usage_count || 0
      _ -> 0
    end
  end

  @doc """
  Returns a map of ingredient_id => usage_count for all ingredients.

  Useful for batch confidence calculations in the parser.
  """
  def get_usage_count_map do
    from(ci in CanonicalIngredient, select: {ci.id, ci.usage_count})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Matches an ingredient name and returns a confidence score.

  The confidence score (0.0-1.0) is based on:
  - Match type: exact name (1.0), alias (0.95), fuzzy (0.5-0.9)
  - Usage boost: common ingredients get a small confidence boost

  Returns `{:ok, %{ingredient: ingredient, confidence: score}}` or `{:error, :not_found}`.

  ## Examples

      iex> match_with_confidence("garlic")
      {:ok, %{ingredient: %CanonicalIngredient{name: "garlic"}, confidence: 0.98}}

      iex> match_with_confidence("xyzabc123")
      {:error, :not_found}
  """
  def match_with_confidence(name) when is_binary(name) do
    normalized = String.downcase(String.trim(name))

    # Try exact name match first
    case Repo.get_by(CanonicalIngredient, name: normalized) do
      %CanonicalIngredient{} = ingredient ->
        confidence = calculate_confidence(:exact, ingredient.usage_count)
        {:ok, %{ingredient: ingredient, confidence: confidence}}

      nil ->
        # Try alias match
        case find_by_alias(normalized) do
          %CanonicalIngredient{} = ingredient ->
            confidence = calculate_confidence(:alias, ingredient.usage_count)
            {:ok, %{ingredient: ingredient, confidence: confidence}}

          nil ->
            {:error, :not_found}
        end
    end
  end

  # Calculate confidence based on match type and usage
  # Base scores: exact = 0.95, alias = 0.90
  # Usage boost: up to 0.05 based on log-scaled usage count
  defp calculate_confidence(match_type, usage_count) do
    base_score =
      case match_type do
        :exact -> 0.95
        :alias -> 0.90
      end

    # Usage boost: log-scale to prevent extreme values from dominating
    # Max boost of 0.05 at ~60k uses (our top ingredients)
    usage_boost =
      if usage_count && usage_count > 0 do
        # log10(60000) ≈ 4.78, so we divide by 5 to get max ~0.05 boost
        min(0.05, :math.log10(usage_count + 1) / 100)
      else
        0.0
      end

    min(1.0, base_score + usage_boost)
  end

  defp find_by_alias(normalized_name) do
    from(ci in CanonicalIngredient,
      where: ^normalized_name in ci.aliases,
      limit: 1
    )
    |> Repo.one()
  end

  # =============================================================================
  # Ingredient Densities
  # =============================================================================

  @doc """
  Gets the density for an ingredient/unit/preparation combination.

  Returns `{:ok, density}` or `{:error, :not_found}`.
  """
  def get_density(canonical_ingredient_id, volume_unit, preparation \\ nil) do
    query =
      from(d in IngredientDensity,
        where:
          d.canonical_ingredient_id == ^canonical_ingredient_id and
            d.volume_unit == ^volume_unit,
        limit: 1
      )

    query =
      if preparation do
        where(query, [d], d.preparation == ^preparation)
      else
        where(query, [d], is_nil(d.preparation))
      end

    case Repo.one(query) do
      %IngredientDensity{} = density -> {:ok, density}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Gets any available density for an ingredient/unit, ignoring preparation.

  First tries to find a density without preparation (base density),
  then falls back to any available density for that unit.
  """
  def get_any_density(canonical_ingredient_id, volume_unit) do
    # First try without preparation
    case get_density(canonical_ingredient_id, volume_unit, nil) do
      {:ok, density} ->
        {:ok, density}

      {:error, :not_found} ->
        # Fall back to any density for this unit
        query =
          from(d in IngredientDensity,
            where:
              d.canonical_ingredient_id == ^canonical_ingredient_id and
                d.volume_unit == ^volume_unit,
            limit: 1
          )

        case Repo.one(query) do
          %IngredientDensity{} = density -> {:ok, density}
          nil -> {:error, :not_found}
        end
    end
  end

  @doc """
  Lists all densities for an ingredient.
  """
  def list_densities(canonical_ingredient_id) do
    from(d in IngredientDensity,
      where: d.canonical_ingredient_id == ^canonical_ingredient_id,
      order_by: [asc: d.volume_unit, asc: d.preparation]
    )
    |> Repo.all()
  end

  @doc """
  Creates an ingredient density.
  """
  def create_density(attrs) do
    %IngredientDensity{}
    |> IngredientDensity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an ingredient density.
  """
  def update_density(%IngredientDensity{} = density, attrs) do
    density
    |> IngredientDensity.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an ingredient density.
  """
  def delete_density(%IngredientDensity{} = density) do
    Repo.delete(density)
  end

  @doc """
  Upserts an ingredient density (insert or update on conflict).
  """
  def upsert_density(attrs) do
    %IngredientDensity{}
    |> IngredientDensity.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:grams_per_unit, :notes, :source_id, :source_url,
                               :confidence, :data_points, :retrieved_at, :last_checked_at,
                               :updated_at]},
      conflict_target: {:unsafe_fragment, ~s|(canonical_ingredient_id, volume_unit, COALESCE(preparation, ''), source) |}
    )
  end

  @doc """
  Bulk inserts ingredient densities.

  Useful for seeding data efficiently.
  """
  def bulk_insert_densities(densities) when is_list(densities) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    entries =
      Enum.map(densities, fn attrs ->
        attrs
        |> Map.put(:id, Ecto.UUID.generate())
        |> Map.put(:inserted_at, now)
        |> Map.put(:updated_at, now)
        |> Map.put_new(:preparation, nil)
      end)

    Repo.insert_all(IngredientDensity, entries,
      on_conflict: :nothing,
      conflict_target: {:unsafe_fragment, ~s|(canonical_ingredient_id, volume_unit, COALESCE(preparation, ''), source) |}
    )
  end

  @doc """
  Lists ingredients that have densities.
  """
  def list_ingredients_with_densities do
    subquery = from(d in IngredientDensity, select: d.canonical_ingredient_id, distinct: true)

    from(ci in CanonicalIngredient,
      where: ci.id in subquery(subquery),
      order_by: ci.name
    )
    |> Repo.all()
  end

  @doc """
  Lists ingredients that don't have density data.
  """
  def list_ingredients_without_densities do
    subquery = from(d in IngredientDensity, select: d.canonical_ingredient_id)

    from(ci in CanonicalIngredient,
      where: ci.id not in subquery(subquery),
      order_by: ci.name
    )
    |> Repo.all()
  end

  @doc """
  Counts ingredients with and without density data.
  """
  def density_coverage_stats do
    total = Repo.aggregate(CanonicalIngredient, :count, :id)

    with_density =
      from(d in IngredientDensity, select: count(d.canonical_ingredient_id, :distinct))
      |> Repo.one!()

    %{
      total_ingredients: total,
      with_density: with_density,
      without_density: total - with_density,
      coverage_percent: if(total > 0, do: Float.round(with_density / total * 100, 1), else: 0)
    }
  end

  # =============================================================================
  # Pending Ingredients
  # =============================================================================

  alias Controlcopypasta.Ingredients.PendingIngredient

  @doc """
  Lists pending ingredients with optional filtering.

  ## Options

  - `:status` - Filter by status (default: "pending")
  - `:limit` - Limit results
  - `:min_occurrences` - Minimum occurrence count
  """
  def list_pending_ingredients(opts \\ []) do
    status = Keyword.get(opts, :status, "pending")
    limit = Keyword.get(opts, :limit)
    offset = Keyword.get(opts, :offset, 0)
    min_occurrences = Keyword.get(opts, :min_occurrences, 0)

    query = from(p in PendingIngredient,
      where: p.status == ^status,
      where: p.occurrence_count >= ^min_occurrences,
      order_by: [desc: p.occurrence_count],
      offset: ^offset
    )

    query = if limit, do: limit(query, ^limit), else: query

    Repo.all(query)
  end

  @doc """
  Clears all pending ingredients (used before re-scanning).
  """
  def clear_pending_ingredients do
    {count, _} = Repo.delete_all(from(p in PendingIngredient, where: p.status == "pending"))
    {:ok, count}
  end

  @doc """
  Gets a pending ingredient by ID.
  """
  def get_pending_ingredient(id) do
    Repo.get(PendingIngredient, id)
  end

  @doc """
  Gets pending ingredient stats.
  """
  def pending_ingredient_stats do
    pending = Repo.aggregate(from(p in PendingIngredient, where: p.status == "pending"), :count, :id)
    approved = Repo.aggregate(from(p in PendingIngredient, where: p.status == "approved"), :count, :id)
    rejected = Repo.aggregate(from(p in PendingIngredient, where: p.status == "rejected"), :count, :id)
    merged = Repo.aggregate(from(p in PendingIngredient, where: p.status == "merged"), :count, :id)
    tool = Repo.aggregate(from(p in PendingIngredient, where: p.status == "tool"), :count, :id)
    preparation = Repo.aggregate(from(p in PendingIngredient, where: p.status == "preparation"), :count, :id)

    %{
      pending: pending,
      approved: approved,
      rejected: rejected,
      merged: merged,
      tool: tool,
      preparation: preparation,
      total: pending + approved + rejected + merged + tool + preparation
    }
  end

  @doc """
  Approves a pending ingredient, creating a new canonical ingredient.
  """
  def approve_pending_ingredient(pending_id, attrs \\ %{}, user_id \\ nil) do
    pending = Repo.get!(PendingIngredient, pending_id)

    # Build canonical ingredient attrs
    canonical_attrs = %{
      name: pending.name,
      display_name: attrs[:display_name] || pending.suggested_display_name || titlecase(pending.name),
      category: attrs[:category] || pending.suggested_category,
      aliases: attrs[:aliases] || pending.suggested_aliases || []
    }

    Repo.transaction(fn ->
      # Create canonical ingredient
      {:ok, canonical} =
        %CanonicalIngredient{}
        |> CanonicalIngredient.changeset(canonical_attrs)
        |> Repo.insert()

      # Update pending status
      {:ok, _} =
        pending
        |> PendingIngredient.changeset(%{
          status: "approved",
          reviewed_at: DateTime.utc_now(),
          reviewed_by_id: user_id
        })
        |> Repo.update()

      canonical
    end)
  end

  @doc """
  Rejects a pending ingredient (marks as not a real ingredient).
  """
  def reject_pending_ingredient(pending_id, user_id \\ nil) do
    pending = Repo.get!(PendingIngredient, pending_id)

    pending
    |> PendingIngredient.changeset(%{
      status: "rejected",
      reviewed_at: DateTime.utc_now(),
      reviewed_by_id: user_id
    })
    |> Repo.update()
  end

  @doc """
  Marks a pending ingredient as a preparation method (not a real ingredient).
  """
  def mark_pending_as_preparation(pending_id, user_id \\ nil) do
    pending = Repo.get!(PendingIngredient, pending_id)

    pending
    |> PendingIngredient.changeset(%{
      status: "preparation",
      reviewed_at: DateTime.utc_now(),
      reviewed_by_id: user_id
    })
    |> Repo.update()
  end

  @doc """
  Marks a pending ingredient as a kitchen tool/utensil (not a real ingredient).
  """
  def mark_pending_as_tool(pending_id, user_id \\ nil) do
    pending = Repo.get!(PendingIngredient, pending_id)

    pending
    |> PendingIngredient.changeset(%{
      status: "tool",
      reviewed_at: DateTime.utc_now(),
      reviewed_by_id: user_id
    })
    |> Repo.update()
  end

  @doc """
  Merges a pending ingredient into an existing canonical as an alias.
  """
  def merge_pending_ingredient(pending_id, canonical_id, user_id \\ nil) do
    pending = Repo.get!(PendingIngredient, pending_id)
    canonical = Repo.get!(CanonicalIngredient, canonical_id)

    Repo.transaction(fn ->
      # Add as alias to canonical
      new_aliases = Enum.uniq([pending.name | canonical.aliases || []])

      {:ok, _} =
        canonical
        |> CanonicalIngredient.changeset(%{aliases: new_aliases})
        |> Repo.update()

      # Update pending status
      {:ok, _} =
        pending
        |> PendingIngredient.changeset(%{
          status: "merged",
          merged_into_id: canonical_id,
          reviewed_at: DateTime.utc_now(),
          reviewed_by_id: user_id
        })
        |> Repo.update()

      canonical
    end)
  end

  @doc """
  Updates a pending ingredient's suggested values.
  """
  def update_pending_ingredient(pending_id, attrs) do
    pending = Repo.get!(PendingIngredient, pending_id)

    pending
    |> PendingIngredient.changeset(attrs)
    |> Repo.update()
  end

  defp titlecase(name) do
    name
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @doc """
  Fixes ingredients that have nutrition data but no primary source selected.

  For each ingredient without a primary, selects the highest-confidence
  nutrition record and sets it as primary.

  Returns {:ok, count} with the number of ingredients fixed.
  """
  def fix_missing_primary_nutrition do
    # Find ingredients with nutrition but no primary
    ingredients_without_primary =
      from(n in IngredientNutrition,
        where: n.is_primary == false or is_nil(n.is_primary),
        group_by: n.canonical_ingredient_id,
        having: fragment("NOT EXISTS (SELECT 1 FROM ingredient_nutrition n2 WHERE n2.canonical_ingredient_id = ? AND n2.is_primary = true)", n.canonical_ingredient_id),
        select: n.canonical_ingredient_id
      )
      |> Repo.all()

    fixed_count =
      Enum.reduce(ingredients_without_primary, 0, fn ingredient_id, count ->
        # Get the highest confidence nutrition for this ingredient
        best_nutrition =
          from(n in IngredientNutrition,
            where: n.canonical_ingredient_id == ^ingredient_id,
            order_by: [desc: n.confidence],
            limit: 1
          )
          |> Repo.one()

        if best_nutrition do
          case set_primary_nutrition(best_nutrition) do
            {:ok, _} -> count + 1
            _ -> count
          end
        else
          count
        end
      end)

    {:ok, fixed_count}
  end

  @doc """
  Returns statistics about nutrition data quality.
  """
  def nutrition_quality_stats do
    total_with_nutrition =
      from(n in IngredientNutrition,
        select: count(fragment("DISTINCT ?", n.canonical_ingredient_id))
      )
      |> Repo.one()

    with_primary =
      from(n in IngredientNutrition,
        where: n.is_primary == true,
        select: count(n.id)
      )
      |> Repo.one()

    by_source =
      from(n in IngredientNutrition,
        group_by: n.source,
        select: {n.source, count(n.id)}
      )
      |> Repo.all()
      |> Map.new()

    primary_by_source =
      from(n in IngredientNutrition,
        where: n.is_primary == true,
        group_by: n.source,
        select: {n.source, count(n.id)}
      )
      |> Repo.all()
      |> Map.new()

    avg_confidence =
      from(n in IngredientNutrition,
        where: n.is_primary == true,
        select: avg(n.confidence)
      )
      |> Repo.one()

    %{
      total_ingredients_with_nutrition: total_with_nutrition,
      with_primary_set: with_primary,
      without_primary: total_with_nutrition - with_primary,
      records_by_source: by_source,
      primary_by_source: primary_by_source,
      avg_primary_confidence: avg_confidence
    }
  end

  @doc """
  Verifies nutrition data quality by checking for anomalies.

  Returns a map of potential issues found in the primary nutrition records.
  """
  def verify_nutrition_quality do
    # Get all primary nutrition records with ingredient names and IDs
    primary_records =
      from(n in IngredientNutrition,
        join: ci in CanonicalIngredient,
        on: ci.id == n.canonical_ingredient_id,
        where: n.is_primary == true,
        where: ci.skip_nutrition == false,
        select: %{
          id: n.id,
          ingredient_id: ci.id,
          ingredient_name: ci.name,
          source: n.source,
          source_name: n.source_name,
          calories: n.calories,
          protein_g: n.protein_g,
          fat_total_g: n.fat_total_g,
          carbohydrates_g: n.carbohydrates_g,
          confidence: n.confidence
        }
      )
      |> Repo.all()

    # Get ingredients without nutrition that aren't marked as skip
    ingredients_without_nutrition =
      from(ci in CanonicalIngredient,
        left_join: n in IngredientNutrition,
        on: n.canonical_ingredient_id == ci.id,
        where: is_nil(n.id),
        where: ci.skip_nutrition == false,
        select: %{id: ci.id, name: ci.name}
      )
      |> Repo.all()

    # Check for missing core macros - include ID for actions
    missing_calories =
      Enum.filter(primary_records, fn r -> is_nil(r.calories) end)
      |> Enum.map(fn r -> %{id: r.ingredient_id, name: r.ingredient_name} end)

    missing_all_macros =
      Enum.filter(primary_records, fn r ->
        is_nil(r.protein_g) and is_nil(r.fat_total_g) and is_nil(r.carbohydrates_g)
      end)
      |> Enum.map(fn r -> %{id: r.ingredient_id, name: r.ingredient_name} end)

    # Check for low confidence records
    low_confidence =
      Enum.filter(primary_records, fn r ->
        r.confidence && Decimal.compare(r.confidence, Decimal.new("0.5")) == :lt
      end)
      |> Enum.map(fn r -> %{id: r.ingredient_id, name: r.ingredient_name, confidence: Decimal.to_float(r.confidence)} end)

    # Check for potentially mismatched source names (different from ingredient name)
    suspicious_matches =
      Enum.filter(primary_records, fn r ->
        r.source_name && r.confidence &&
          Decimal.compare(r.confidence, Decimal.new("0.65")) == :lt
      end)
      |> Enum.map(fn r ->
        %{
          id: r.ingredient_id,
          ingredient: r.ingredient_name,
          matched_to: r.source_name,
          source: r.source,
          confidence: Decimal.to_float(r.confidence)
        }
      end)
      |> Enum.sort_by(& &1.confidence)
      |> Enum.take(20)

    %{
      total_primary_records: length(primary_records),
      issues: %{
        missing_calories: missing_calories,
        missing_all_macros: missing_all_macros,
        missing_nutrition: Enum.take(ingredients_without_nutrition, 20),
        low_confidence_count: length(low_confidence),
        low_confidence_samples: Enum.take(low_confidence, 10)
      },
      suspicious_matches: suspicious_matches,
      summary: %{
        has_issues: length(missing_calories) > 0 or length(missing_all_macros) > 0 or length(ingredients_without_nutrition) > 0,
        missing_calories_count: length(missing_calories),
        missing_all_macros_count: length(missing_all_macros),
        missing_nutrition_count: length(ingredients_without_nutrition)
      }
    }
  end
end
