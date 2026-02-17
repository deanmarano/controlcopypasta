defmodule Controlcopypasta.Recipes do
  @moduledoc """
  The Recipes context for managing recipes and tags.
  """

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Recipes.{Recipe, Tag, IngredientDecision}
  alias Controlcopypasta.Similarity.{IngredientParser, IngredientNormalizer}

  # Recipes

  def list_recipes(params \\ %{}) do
    Recipe
    |> apply_archived_filter(params)
    |> apply_filters(params)
    |> apply_search(params)
    |> apply_pagination(params)
    |> preload(:tags)
    |> Repo.all()
  end

  def list_recipes_for_user(user_id, params \\ %{}) do
    Recipe
    |> where([r], r.user_id == ^user_id)
    |> apply_archived_filter(params)
    |> apply_filters(params)
    |> apply_search(params)
    |> apply_pagination(params)
    |> preload(:tags)
    |> Repo.all()
  end

  def get_recipe(id) do
    Recipe
    |> preload(:tags)
    |> Repo.get(id)
  end

  def get_recipe!(id) do
    Recipe
    |> preload(:tags)
    |> Repo.get!(id)
  end

  def get_recipe_for_user(user_id, id) do
    Recipe
    |> where([r], r.user_id == ^user_id)
    |> preload(:tags)
    |> Repo.get(id)
  end

  def get_recipe_by_source_url(user_id, source_url) do
    Recipe
    |> where([r], r.user_id == ^user_id and r.source_url == ^source_url)
    |> preload(:tags)
    |> Repo.one()
  end

  def list_domains do
    alias Controlcopypasta.Recipes.Domain

    Recipe
    |> where([r], not is_nil(r.source_domain))
    |> join(:left, [r], d in Domain, on: r.source_domain == d.domain)
    |> group_by([r, d], [r.source_domain, d.favicon_url, d.screenshot_captured_at])
    |> select([r, d], %{
      domain: r.source_domain,
      count: count(r.id),
      has_screenshot: not is_nil(d.screenshot_captured_at),
      favicon_url: d.favicon_url
    })
    |> order_by([r], desc: count(r.id))
    |> Repo.all()
  end

  def get_domain_screenshot(domain_name) do
    alias Controlcopypasta.Recipes.Domain

    Domain
    |> where([d], d.domain == ^domain_name)
    |> where([d], not is_nil(d.screenshot))
    |> select([d], d.screenshot)
    |> Repo.one()
  end

  def list_recipes_by_domain(domain, params \\ %{}) do
    Recipe
    |> where([r], r.source_domain == ^domain or r.source_domain == ^"www.#{domain}")
    |> apply_archived_filter(params)
    |> apply_search(params)
    |> apply_avoided_filter(params)
    |> apply_pagination(params)
    |> preload(:tags)
    |> Repo.all()
  end

  def count_recipes_by_domain(domain, params \\ %{}) do
    Recipe
    |> where([r], r.source_domain == ^domain or r.source_domain == ^"www.#{domain}")
    |> apply_archived_filter(params)
    |> apply_search(params)
    |> apply_avoided_filter(params)
    |> Repo.aggregate(:count)
  end

  def get_recipe_by_domain(domain, id) do
    Recipe
    |> where([r], r.source_domain == ^domain or r.source_domain == ^"www.#{domain}")
    |> where([r], r.id == ^id)
    |> preload(:tags)
    |> Repo.one()
  end

  def create_recipe(attrs \\ %{}) do
    %Recipe{}
    |> Recipe.changeset(attrs)
    |> maybe_put_tags(attrs)
    |> Repo.insert()
    |> case do
      {:ok, recipe} -> {:ok, Repo.preload(recipe, :tags)}
      error -> error
    end
  end

  def update_recipe(%Recipe{} = recipe, attrs) do
    recipe
    |> Recipe.changeset(attrs)
    |> maybe_put_tags(attrs)
    |> Repo.update()
    |> case do
      {:ok, recipe} -> {:ok, Repo.preload(recipe, :tags, force: true)}
      error -> error
    end
  end

  def delete_recipe(%Recipe{} = recipe) do
    Repo.delete(recipe)
  end

  def archive_recipe(%Recipe{} = recipe) do
    recipe
    |> Ecto.Changeset.change(archived_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
  end

  def unarchive_recipe(%Recipe{} = recipe) do
    recipe
    |> Ecto.Changeset.change(archived_at: nil)
    |> Repo.update()
  end

  def archived?(%Recipe{archived_at: nil}), do: false
  def archived?(%Recipe{archived_at: _}), do: true

  defp apply_archived_filter(query, %{"archived" => "true"}) do
    where(query, [r], not is_nil(r.archived_at))
  end

  defp apply_archived_filter(query, %{"archived" => "all"}) do
    query
  end

  defp apply_archived_filter(query, _params) do
    # By default, exclude archived recipes
    where(query, [r], is_nil(r.archived_at))
  end

  defp apply_filters(query, %{"tag" => tag_name}) when is_binary(tag_name) do
    from r in query,
      join: t in assoc(r, :tags),
      where: t.name == ^tag_name
  end

  defp apply_filters(query, _), do: query

  defp apply_search(query, %{"q" => search_term}) when is_binary(search_term) and search_term != "" do
    search_pattern = "%#{search_term}%"

    from r in query,
      where: ilike(r.title, ^search_pattern) or ilike(r.description, ^search_pattern)
  end

  defp apply_search(query, _), do: query

  # Filter out recipes that contain any of the avoided canonical ingredient IDs or names
  defp apply_avoided_filter(query, %{"exclude_ingredient_ids" => ids})
       when is_list(ids) and ids != [] do
    # Convert MapSet to list if needed
    id_list = if is_struct(ids, MapSet), do: MapSet.to_list(ids), else: ids

    # Use denormalized columns for fast filtering:
    # - all_ingredients_parsed: true when no unparsed ingredients
    # - ingredient_canonical_ids: flat array for GIN-indexed overlap check
    from r in query,
      where:
        r.all_ingredients_parsed == true and
        fragment("NOT (? && ?)", r.ingredient_canonical_ids, ^id_list)
  end

  defp apply_avoided_filter(query, _), do: query

  defp apply_pagination(query, params) do
    limit = Map.get(params, "limit", "50") |> parse_int(50) |> min(100)
    offset = Map.get(params, "offset", "0") |> parse_int(0)

    from r in query,
      order_by: [desc: r.updated_at],
      limit: ^limit,
      offset: ^offset
  end

  defp parse_int(val, default) when is_binary(val) do
    case Integer.parse(val) do
      {int, _} -> int
      :error -> default
    end
  end

  defp parse_int(val, _default) when is_integer(val), do: val
  defp parse_int(_, default), do: default

  defp maybe_put_tags(changeset, attrs) do
    tags_by_id = resolve_tag_ids(attrs)
    tags_by_name = resolve_tag_names(attrs)

    all_tags =
      (tags_by_id ++ tags_by_name)
      |> Enum.uniq_by(& &1.id)

    if all_tags == [] do
      changeset
    else
      Ecto.Changeset.put_assoc(changeset, :tags, all_tags)
    end
  end

  defp resolve_tag_ids(%{"tag_ids" => tag_ids}) when is_list(tag_ids) and tag_ids != [] do
    Repo.all(from t in Tag, where: t.id in ^tag_ids)
  end

  defp resolve_tag_ids(%{tag_ids: tag_ids}) when is_list(tag_ids) and tag_ids != [] do
    Repo.all(from t in Tag, where: t.id in ^tag_ids)
  end

  defp resolve_tag_ids(_), do: []

  defp resolve_tag_names(%{"tag_names" => names}) when is_list(names) and names != [] do
    Enum.reduce(names, [], fn name, acc ->
      case get_or_create_tag(name) do
        {:ok, tag} -> [tag | acc]
        _ -> acc
      end
    end)
  end

  defp resolve_tag_names(%{tag_names: names}) when is_list(names) and names != [] do
    Enum.reduce(names, [], fn name, acc ->
      case get_or_create_tag(name) do
        {:ok, tag} -> [tag | acc]
        _ -> acc
      end
    end)
  end

  defp resolve_tag_names(_), do: []

  # Avoided Ingredients Checking

  def recipe_contains_avoided?(recipe, avoided_set) when is_struct(avoided_set, MapSet) do
    if MapSet.size(avoided_set) == 0 do
      false
    else
      recipe.ingredients
      |> Enum.any?(fn ingredient ->
        parsed = IngredientParser.parse_ingredient_map(ingredient)
        canonical = IngredientNormalizer.normalize(parsed.name)
        ingredient_matches_avoided?(canonical, avoided_set)
      end)
    end
  end

  def get_avoided_ingredients_in_recipe(recipe, avoided_set) when is_struct(avoided_set, MapSet) do
    if MapSet.size(avoided_set) == 0 do
      []
    else
      recipe.ingredients
      |> Enum.map(fn ingredient ->
        parsed = IngredientParser.parse_ingredient_map(ingredient)
        canonical = IngredientNormalizer.normalize(parsed.name)
        {ingredient, parsed, canonical}
      end)
      |> Enum.filter(fn {_ingredient, _parsed, canonical} ->
        ingredient_matches_avoided?(canonical, avoided_set)
      end)
      |> Enum.map(fn {ingredient, parsed, canonical} ->
        %{
          name: parsed.name,
          canonical: canonical,
          original: ingredient["text"] || parsed.original
        }
      end)
      |> Enum.uniq_by(& &1.canonical)
    end
  end

  defp ingredient_matches_avoided?(canonical, avoided_set) do
    # Check exact match first
    if MapSet.member?(avoided_set, canonical) do
      true
    else
      # Check if ingredient contains any avoided term (e.g., "chicken breast" contains "chicken")
      Enum.any?(avoided_set, fn avoided ->
        String.contains?(canonical, avoided) or String.contains?(avoided, canonical)
      end)
    end
  end

  # Dashboard queries

  def random_recipes_for_user(user_id, count, params \\ %{}) do
    Recipe
    |> where([r], r.user_id == ^user_id)
    |> apply_archived_filter(%{})
    |> apply_avoided_filter(params)
    |> order_by(fragment("RANDOM()"))
    |> limit(^count)
    |> preload(:tags)
    |> Repo.all()
  end

  def dinner_recipes_for_user(user_id, count, params \\ %{}) do
    # Query dinner-tagged recipes from ALL users (global discovery)
    dinner_tagged =
      Recipe
      |> join(:inner, [r], t in assoc(r, :tags))
      |> where([r, t], t.name == "dinner")
      |> where([r], not is_nil(r.image_url) and r.image_url != "")
      |> apply_archived_filter(%{})
      |> apply_avoided_filter(params)
      |> order_by(fragment("RANDOM()"))
      |> limit(^count)
      |> preload(:tags)
      |> Repo.all()

    # If we don't have enough, fill with the user's own recipes
    if length(dinner_tagged) < count do
      remaining = count - length(dinner_tagged)
      dinner_ids = Enum.map(dinner_tagged, & &1.id)

      fillers =
        Recipe
        |> where([r], r.user_id == ^user_id)
        |> where([r], r.id not in ^dinner_ids)
        |> apply_archived_filter(%{})
        |> apply_avoided_filter(params)
        |> order_by(fragment("RANDOM()"))
        |> limit(^remaining)
        |> preload(:tags)
        |> Repo.all()

      dinner_tagged ++ fillers
    else
      dinner_tagged
    end
  end

  def recent_recipes_for_user(user_id, count) do
    Recipe
    |> where([r], r.user_id == ^user_id)
    |> apply_archived_filter(%{})
    |> order_by([r], desc: r.inserted_at)
    |> limit(^count)
    |> preload(:tags)
    |> Repo.all()
  end

  def this_time_last_year_for_user(user_id, count) do
    now = Date.utc_today()
    last_year = Date.add(now, -365)
    window_start = Date.add(last_year, -14)
    window_end = Date.add(last_year, 14)

    Recipe
    |> where([r], r.user_id == ^user_id)
    |> apply_archived_filter(%{})
    |> where([r], fragment("?::date", r.inserted_at) >= ^window_start)
    |> where([r], fragment("?::date", r.inserted_at) <= ^window_end)
    |> order_by(fragment("RANDOM()"))
    |> limit(^count)
    |> preload(:tags)
    |> Repo.all()
  end

  def copy_recipe(recipe_id, user_id) do
    case Repo.get(Recipe, recipe_id) |> Repo.preload(:tags) do
      nil ->
        {:error, :not_found}

      recipe ->
        attrs = %{
          "title" => recipe.title,
          "description" => recipe.description,
          "source_url" => recipe.source_url,
          "source_domain" => recipe.source_domain,
          "image_url" => recipe.image_url,
          "ingredients" => recipe.ingredients,
          "instructions" => recipe.instructions,
          "prep_time_minutes" => recipe.prep_time_minutes,
          "cook_time_minutes" => recipe.cook_time_minutes,
          "total_time_minutes" => recipe.total_time_minutes,
          "servings" => recipe.servings,
          "notes" => recipe.notes,
          "source_json_ld" => recipe.source_json_ld,
          "user_id" => user_id,
          "tag_ids" => Enum.map(recipe.tags, & &1.id)
        }

        create_recipe(attrs)
    end
  end

  # Tags

  def list_tags do
    Tag
    |> order_by(:name)
    |> Repo.all()
  end

  def get_tag(id), do: Repo.get(Tag, id)

  def get_tag!(id), do: Repo.get!(Tag, id)

  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  def get_or_create_tag(name) when is_binary(name) do
    case Repo.get_by(Tag, name: name) do
      nil -> create_tag(%{name: name})
      tag -> {:ok, tag}
    end
  end

  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end

  # Ingredient Decisions

  @doc """
  Lists all ingredient decisions for a recipe by a specific user.
  """
  def list_decisions(recipe_id, user_id) do
    IngredientDecision
    |> where([d], d.recipe_id == ^recipe_id and d.user_id == ^user_id)
    |> order_by([d], d.ingredient_index)
    |> Repo.all()
  end

  @doc """
  Gets ingredient decisions as a map keyed by ingredient index.
  """
  def get_decisions_map(recipe_id, user_id) do
    list_decisions(recipe_id, user_id)
    |> Map.new(fn d -> {d.ingredient_index, d} end)
  end

  @doc """
  Creates or updates a decision for an ingredient.
  Uses upsert to handle unique constraint.
  """
  def save_decision(attrs) do
    %IngredientDecision{}
    |> IngredientDecision.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:selected_canonical_id, :selected_name, :updated_at]},
      conflict_target: [:recipe_id, :user_id, :ingredient_index]
    )
  end

  @doc """
  Deletes a specific ingredient decision.
  """
  def delete_decision(recipe_id, user_id, ingredient_index) do
    IngredientDecision
    |> where([d], d.recipe_id == ^recipe_id and d.user_id == ^user_id and d.ingredient_index == ^ingredient_index)
    |> Repo.delete_all()
  end

  @doc """
  Deletes all ingredient decisions for a recipe by a user.
  """
  def clear_decisions(recipe_id, user_id) do
    IngredientDecision
    |> where([d], d.recipe_id == ^recipe_id and d.user_id == ^user_id)
    |> Repo.delete_all()
  end
end
