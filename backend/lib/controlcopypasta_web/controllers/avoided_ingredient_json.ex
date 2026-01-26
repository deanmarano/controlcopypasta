defmodule ControlcopypastaWeb.AvoidedIngredientJSON do
  alias Controlcopypasta.Accounts.AvoidedIngredient

  def index(%{avoided_ingredients: avoided_ingredients}) do
    %{data: for(item <- avoided_ingredients, do: data(item))}
  end

  def show(%{avoided_ingredient: avoided_ingredient}) do
    %{data: data(avoided_ingredient)}
  end

  defp data(%AvoidedIngredient{} = item) do
    %{
      id: item.id,
      canonical_name: item.canonical_name,
      display_name: item.display_name,
      inserted_at: item.inserted_at
    }
  end
end
