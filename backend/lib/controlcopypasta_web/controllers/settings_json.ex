defmodule ControlcopypastaWeb.SettingsJSON do
  def preferences(%{preferences: preferences, is_admin: is_admin}) do
    %{data: Map.put(preferences, :is_admin, is_admin)}
  end

  def preferences(%{preferences: preferences}) do
    %{data: preferences}
  end
end
