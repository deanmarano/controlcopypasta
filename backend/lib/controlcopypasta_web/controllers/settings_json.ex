defmodule ControlcopypastaWeb.SettingsJSON do
  def preferences(%{preferences: preferences}) do
    %{data: preferences}
  end
end
