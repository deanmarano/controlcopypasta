defmodule Controlcopypasta.Scraper.Domain do
  @moduledoc """
  Schema for domain metadata including screenshots and favicons.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "domains" do
    field :domain, :string
    field :display_name, :string
    field :favicon_url, :string
    field :screenshot, :binary
    field :screenshot_captured_at, :utc_datetime

    timestamps()
  end

  def changeset(domain, attrs) do
    domain
    |> cast(attrs, [:domain, :display_name, :favicon_url, :screenshot, :screenshot_captured_at])
    |> validate_required([:domain])
    |> unique_constraint(:domain)
    |> normalize_domain()
  end

  defp normalize_domain(changeset) do
    case get_change(changeset, :domain) do
      nil -> changeset
      domain -> put_change(changeset, :domain, String.downcase(String.replace(domain, ~r/^www\./, "")))
    end
  end
end
