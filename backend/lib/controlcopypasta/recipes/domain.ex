defmodule Controlcopypasta.Recipes.Domain do
  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "domains" do
    field :domain, :string
    field :display_name, :string
    field :favicon_url, :string
    field :screenshot, :binary
    field :screenshot_captured_at, :utc_datetime

    timestamps()
  end
end
