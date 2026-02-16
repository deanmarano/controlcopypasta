defmodule ControlcopypastaWeb.DashboardController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Ingredients

  action_fallback ControlcopypastaWeb.FallbackController

  def index(conn, _params) do
    user = conn.assigns.current_user
    avoided_params = build_avoided_params(user)

    dinner_task = Task.async(fn -> Recipes.dinner_recipes_for_user(user.id, 6, avoided_params) end)
    recent_task = Task.async(fn -> Recipes.recent_recipes_for_user(user.id, 6) end)
    last_year_task = Task.async(fn -> Recipes.this_time_last_year_for_user(user.id, 6) end)

    dinner_ideas = Task.await(dinner_task)
    recently_added = Task.await(recent_task)
    this_time_last_year = Task.await(last_year_task)

    avoided_set = Accounts.get_avoided_canonical_ids(user.id)

    render(conn, :index,
      dinner_ideas: dinner_ideas,
      recently_added: recently_added,
      this_time_last_year: this_time_last_year,
      avoided_set: avoided_set,
      user_id: user.id
    )
  end

  defp build_avoided_params(user) do
    if user.hide_avoided_ingredients do
      avoided_ids = Accounts.get_avoided_canonical_ids(user.id)

      if MapSet.size(avoided_ids) > 0 do
        avoided_names = Ingredients.list_canonical_names_by_ids(avoided_ids)

        %{
          "exclude_ingredient_ids" => MapSet.to_list(avoided_ids),
          "exclude_ingredient_names" => avoided_names
        }
      else
        %{}
      end
    else
      %{}
    end
  end
end
