defmodule ControlcopypastaWeb.Admin.KitchenToolJSON do
  @doc """
  Renders a list of kitchen tools for admin.
  """
  def index(%{kitchen_tools: kitchen_tools}) do
    %{data: for(kitchen_tool <- kitchen_tools, do: data(kitchen_tool))}
  end

  @doc """
  Renders a single kitchen tool.
  """
  def show(%{kitchen_tool: kitchen_tool}) do
    %{data: data(kitchen_tool)}
  end

  @doc """
  Renders options for admin forms.
  """
  def options(%{categories: categories}) do
    %{categories: categories}
  end

  defp data(kitchen_tool) do
    %{
      id: kitchen_tool.id,
      name: kitchen_tool.name,
      display_name: kitchen_tool.display_name,
      category: kitchen_tool.category,
      metadata: kitchen_tool.metadata || %{},
      aliases: kitchen_tool.aliases || []
    }
  end
end
