defmodule Controlcopypasta.Recipes.Recipe do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "recipes" do
    field :title, :string
    field :description, :string
    field :source_url, :string
    field :source_domain, :string
    field :image_url, :string
    field :ingredients, {:array, :map}, default: []
    field :instructions, {:array, :map}, default: []
    field :prep_time_minutes, :integer
    field :cook_time_minutes, :integer
    field :total_time_minutes, :integer
    field :servings, :string
    field :notes, :string
    field :archived_at, :utc_datetime
    field :ingredients_parsed_at, :utc_datetime
    field :source_json_ld, :map

    # Per-serving nutrition from Schema.org JSON-LD
    field :nutrition_serving_size, :string
    field :nutrition_calories, :decimal
    field :nutrition_protein_g, :decimal
    field :nutrition_fat_g, :decimal
    field :nutrition_saturated_fat_g, :decimal
    field :nutrition_trans_fat_g, :decimal
    field :nutrition_carbohydrates_g, :decimal
    field :nutrition_fiber_g, :decimal
    field :nutrition_sugar_g, :decimal
    field :nutrition_sodium_mg, :decimal
    field :nutrition_cholesterol_mg, :decimal

    # Denormalized columns for fast avoided-ingredient filtering
    field :all_ingredients_parsed, :boolean, default: false
    field :ingredient_canonical_ids, {:array, :string}, default: []

    belongs_to :user, Controlcopypasta.Accounts.User
    many_to_many :tags, Controlcopypasta.Recipes.Tag, join_through: "recipe_tags"

    timestamps()
  end

  @required_fields [:title]
  @optional_fields [
    :description,
    :source_url,
    :source_domain,
    :image_url,
    :ingredients,
    :instructions,
    :prep_time_minutes,
    :cook_time_minutes,
    :total_time_minutes,
    :servings,
    :notes,
    :user_id,
    :ingredients_parsed_at,
    :source_json_ld,
    :nutrition_serving_size,
    :nutrition_calories,
    :nutrition_protein_g,
    :nutrition_fat_g,
    :nutrition_saturated_fat_g,
    :nutrition_trans_fat_g,
    :nutrition_carbohydrates_g,
    :nutrition_fiber_g,
    :nutrition_sugar_g,
    :nutrition_sodium_mg,
    :nutrition_cholesterol_mg
  ]

  def changeset(recipe, attrs) do
    recipe
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> maybe_extract_domain()
  end

  defp maybe_extract_domain(changeset) do
    case get_change(changeset, :source_url) do
      nil ->
        changeset

      url ->
        case URI.parse(url) do
          %URI{host: host} when is_binary(host) ->
            normalized = host |> String.downcase() |> String.replace(~r/^www\./, "")
            put_change(changeset, :source_domain, normalized)

          _ ->
            changeset
        end
    end
  end
end
