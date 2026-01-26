defmodule Controlcopypasta.Scraper.ScrapeUrl do
  @moduledoc """
  Schema for tracking URLs to be scraped.

  Statuses:
  - pending: URL is queued for scraping
  - processing: Currently being scraped
  - completed: Successfully scraped and recipe created
  - failed: Scraping failed after max attempts
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "scrape_urls" do
    field :url, :string
    field :domain, :string
    field :status, :string, default: "pending"
    field :error, :string
    field :attempts, :integer, default: 0

    belongs_to :recipe, Controlcopypasta.Recipes.Recipe

    timestamps()
  end

  @doc false
  def changeset(scrape_url, attrs) do
    scrape_url
    |> cast(attrs, [:url, :domain, :status, :error, :recipe_id, :attempts])
    |> validate_required([:url, :domain])
    |> validate_inclusion(:status, ["pending", "processing", "completed", "failed"])
    |> unique_constraint(:url)
    |> maybe_extract_domain()
  end

  defp maybe_extract_domain(changeset) do
    case get_change(changeset, :url) do
      nil ->
        changeset

      url ->
        case get_field(changeset, :domain) do
          nil ->
            case URI.parse(url) do
              %URI{host: host} when is_binary(host) ->
                put_change(changeset, :domain, normalize_domain(host))

              _ ->
                changeset
            end

          _ ->
            changeset
        end
    end
  end

  defp normalize_domain(domain) do
    domain
    |> String.downcase()
    |> String.replace(~r/^www\./, "")
  end
end
