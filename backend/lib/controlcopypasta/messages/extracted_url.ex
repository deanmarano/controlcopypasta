defmodule Controlcopypasta.Messages.ExtractedUrl do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_sources ~w(message_text shared_content forwarded_content)
  @valid_parse_statuses ~w(pending success failed)

  schema "dm_extracted_urls" do
    field :url, :string
    field :source, :string
    field :parse_status, :string, default: "pending"
    field :parse_error, :string
    field :parsed_recipe_data, :map

    belongs_to :direct_message, Controlcopypasta.Messages.DirectMessage
    belongs_to :recipe, Controlcopypasta.Recipes.Recipe

    timestamps()
  end

  def changeset(extracted_url, attrs) do
    extracted_url
    |> cast(attrs, [
      :direct_message_id,
      :url,
      :source,
      :parse_status,
      :parse_error,
      :parsed_recipe_data,
      :recipe_id
    ])
    |> validate_required([:direct_message_id, :url, :source])
    |> validate_inclusion(:source, @valid_sources)
    |> validate_inclusion(:parse_status, @valid_parse_statuses)
    |> foreign_key_constraint(:direct_message_id)
    |> foreign_key_constraint(:recipe_id)
  end
end
