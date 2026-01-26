defmodule ControlcopypastaWeb.AvoidedIngredientController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Accounts.AvoidedIngredient

  action_fallback ControlcopypastaWeb.FallbackController

  def index(conn, _params) do
    user = conn.assigns.current_user
    avoided_ingredients = Accounts.list_avoided_ingredients(user.id)
    render(conn, :index, avoided_ingredients: avoided_ingredients)
  end

  def create(conn, %{"avoided_ingredient" => params}) do
    user = conn.assigns.current_user

    with {:ok, %AvoidedIngredient{} = avoided} <-
           Accounts.create_avoided_ingredient(user.id, params) do
      conn
      |> put_status(:created)
      |> render(:show, avoided_ingredient: avoided)
    end
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user

    case Accounts.get_avoided_ingredient(user.id, id) do
      nil ->
        {:error, :not_found}

      avoided ->
        with {:ok, %AvoidedIngredient{}} <- Accounts.delete_avoided_ingredient(avoided) do
          send_resp(conn, :no_content, "")
        end
    end
  end
end
