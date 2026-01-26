defmodule ControlcopypastaWeb.ImportController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Import.CopyMeThat

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Import recipes from Copy Me That JSON export.

  POST /api/import/copymthat
  Body: { "recipes": [...] } or raw array [...]
  """
  def copy_me_that(conn, %{"recipes" => recipes}) when is_list(recipes) do
    user = conn.assigns.current_user
    do_import(conn, recipes, user.id)
  end

  def copy_me_that(conn, recipes) when is_list(recipes) do
    user = conn.assigns.current_user
    do_import(conn, recipes, user.id)
  end

  def copy_me_that(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Expected 'recipes' array or raw JSON array"})
  end

  defp do_import(conn, recipes, user_id) do
    case CopyMeThat.import_json(recipes, user_id) do
      {:ok, result} ->
        json(conn, %{
          message: "Import completed",
          imported: result.imported,
          failed: result.failed,
          errors:
            Enum.map(result.errors, fn {name, changeset} ->
              %{
                recipe: name,
                errors: format_errors(changeset)
              }
            end)
        })

      {:error, reason} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Import failed: #{inspect(reason)}"})
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
