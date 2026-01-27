defmodule ControlcopypastaWeb.SettingsController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Accounts

  action_fallback ControlcopypastaWeb.FallbackController

  @doc """
  Returns the current user's preferences.
  """
  def show_preferences(conn, _params) do
    user = conn.assigns.current_user
    preferences = Accounts.get_user_preferences(user)
    render(conn, :preferences, preferences: preferences)
  end

  @doc """
  Updates the current user's preferences.

  ## Parameters

  - hide_avoided_ingredients: boolean - Whether to hide recipes containing avoided ingredients when browsing
  """
  def update_preferences(conn, %{"preferences" => params}) do
    user = conn.assigns.current_user

    case Accounts.update_user_preferences(user, params) do
      {:ok, updated_user} ->
        preferences = Accounts.get_user_preferences(updated_user)
        render(conn, :preferences, preferences: preferences)

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
