defmodule ControlcopypastaWeb.Admin.PreparationJSON do
  @doc """
  Renders a list of preparations for admin.
  """
  def index(%{preparations: preparations}) do
    %{data: for(preparation <- preparations, do: data(preparation))}
  end

  @doc """
  Renders a single preparation.
  """
  def show(%{preparation: preparation}) do
    %{data: data(preparation)}
  end

  @doc """
  Renders options for admin forms.
  """
  def options(%{categories: categories}) do
    %{categories: categories}
  end

  defp data(preparation) do
    %{
      id: preparation.id,
      name: preparation.name,
      display_name: preparation.display_name,
      category: preparation.category,
      verb: preparation.verb,
      metadata: preparation.metadata || %{},
      aliases: preparation.aliases || []
    }
  end
end
