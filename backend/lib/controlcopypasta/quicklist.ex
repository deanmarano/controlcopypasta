defmodule Controlcopypasta.Quicklist do
  @moduledoc """
  Context for the dinner quicklist swipe feature.
  """

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Quicklist.Swipe
  alias Controlcopypasta.Recipes.Recipe

  @doc """
  Gets a batch of recipes for swiping, using a single query with ROW_NUMBER()
  to round-robin across domains. Excludes already-swiped recipes via subquery,
  requires image_url, and applies avoided ingredient filter.
  Optional tag filter restricts results to recipes with the given tag.
  """
  def get_swipe_batch(user_id, count, avoided_params \\ %{}, tag \\ nil) do
    swiped_subquery = swiped_recipe_ids_query(user_id)
    per_domain = max(div(count, 5), 2)

    # Base query: unswiped recipes with images, not archived
    base =
      Recipe
      |> where([r], not is_nil(r.image_url) and r.image_url != "")
      |> where([r], is_nil(r.archived_at))
      |> where([r], r.id not in subquery(swiped_subquery))
      |> apply_tag_filter(tag)
      |> apply_avoided_filter(avoided_params)

    # Ranked subquery: assign row_number per domain, ordered randomly
    ranked =
      from r in base,
        select: %{
          id: r.id,
          rn:
            fragment(
              "ROW_NUMBER() OVER (PARTITION BY ? ORDER BY RANDOM())",
              r.source_domain
            )
        }

    # Outer query: join ranked back, take top N per domain, shuffle, limit
    recipes =
      from(r in Recipe,
        join: ranked in subquery(ranked),
        on: ranked.id == r.id,
        where: ranked.rn <= ^per_domain,
        order_by: fragment("RANDOM()"),
        limit: ^count,
        preload: [:tags]
      )
      |> Repo.all()

    # If we don't have enough, fill with a simple fallback
    if length(recipes) < count do
      existing_ids = Enum.map(recipes, & &1.id)
      remaining = count - length(recipes)
      fillers = fallback_query(user_id, existing_ids, remaining, avoided_params, tag)
      recipes ++ fillers
    else
      recipes
    end
  end

  @doc """
  Records a swipe action (maybe or skip). Upserts if already swiped.
  """
  def record_swipe(user_id, recipe_id, action) do
    attrs = %{user_id: user_id, recipe_id: recipe_id, action: action}

    %Swipe{}
    |> Swipe.changeset(attrs)
    |> Repo.insert(
      on_conflict: [set: [action: action, updated_at: DateTime.utc_now()]],
      conflict_target: [:user_id, :recipe_id]
    )
  end

  @doc """
  Lists all "maybe" recipes for a user, most recent first.
  """
  def list_maybe_recipes(user_id) do
    recipe_ids =
      Swipe
      |> where([s], s.user_id == ^user_id and s.action == "maybe")
      |> order_by([s], desc: s.updated_at)
      |> select([s], s.recipe_id)
      |> Repo.all()

    Recipe
    |> where([r], r.id in ^recipe_ids)
    |> preload(:tags)
    |> Repo.all()
    # Preserve the ordering from the swipe query
    |> Enum.sort_by(fn r -> Enum.find_index(recipe_ids, &(&1 == r.id)) end)
  end

  @doc """
  Removes a recipe from the maybe list (deletes the swipe record so it reappears).
  """
  def remove_from_maybe(user_id, recipe_id) do
    Swipe
    |> where([s], s.user_id == ^user_id and s.recipe_id == ^recipe_id)
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Returns the count of "maybe" recipes for a user.
  """
  def maybe_count(user_id) do
    Swipe
    |> where([s], s.user_id == ^user_id and s.action == "maybe")
    |> Repo.aggregate(:count, :id)
  end

  # Private helpers

  defp swiped_recipe_ids_query(user_id) do
    Swipe
    |> where([s], s.user_id == ^user_id)
    |> select([s], s.recipe_id)
  end

  defp fallback_query(user_id, extra_exclude_ids, count, avoided_params, tag) do
    swiped_subquery = swiped_recipe_ids_query(user_id)

    Recipe
    |> where([r], not is_nil(r.image_url) and r.image_url != "")
    |> where([r], is_nil(r.archived_at))
    |> where([r], r.id not in subquery(swiped_subquery))
    |> exclude_ids(extra_exclude_ids)
    |> apply_tag_filter(tag)
    |> apply_avoided_filter(avoided_params)
    |> order_by(fragment("RANDOM()"))
    |> limit(^count)
    |> preload(:tags)
    |> Repo.all()
  end

  defp exclude_ids(query, []), do: query

  defp exclude_ids(query, ids) do
    where(query, [r], r.id not in ^ids)
  end

  defp apply_tag_filter(query, nil), do: query
  defp apply_tag_filter(query, ""), do: query

  defp apply_tag_filter(query, tag) do
    query
    |> join(:inner, [r], t in assoc(r, :tags))
    |> where([r, t], t.name == ^tag)
  end

  defp apply_avoided_filter(query, %{"exclude_ingredient_ids" => ids})
       when is_list(ids) and ids != [] do
    id_list = if is_struct(ids, MapSet), do: MapSet.to_list(ids), else: ids

    from r in query,
      where:
        r.all_ingredients_parsed == true and
        fragment("NOT (? && ?)", r.ingredient_canonical_ids, ^id_list)
  end

  defp apply_avoided_filter(query, _), do: query
end
