defmodule ControlcopypastaWeb.TagController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Recipes
  alias Controlcopypasta.Recipes.Tag

  action_fallback ControlcopypastaWeb.FallbackController

  def index(conn, _params) do
    tags = Recipes.list_tags()
    render(conn, :index, tags: tags)
  end

  def create(conn, %{"tag" => tag_params}) do
    with {:ok, %Tag{} = tag} <- Recipes.create_tag(tag_params) do
      conn
      |> put_status(:created)
      |> render(:show, tag: tag)
    end
  end

  def delete(conn, %{"id" => id}) do
    case Recipes.get_tag(id) do
      nil ->
        {:error, :not_found}

      tag ->
        with {:ok, %Tag{}} <- Recipes.delete_tag(tag) do
          send_resp(conn, :no_content, "")
        end
    end
  end
end
