defmodule Controlcopypasta.Ingredients.BrandPackageSize do
  @moduledoc """
  Schema for tracking standard package sizes for branded products.

  This helps with recipe scaling by knowing what sizes are actually
  available for purchase (e.g., Coca-Cola comes in 12oz cans, 20oz bottles, 2L bottles).

  ## Examples

      %BrandPackageSize{
        package_type: "can",
        size_value: Decimal.new("12"),
        size_unit: "oz",
        label: "12 oz can",
        is_default: true
      }

      %BrandPackageSize{
        package_type: "bottle",
        size_value: Decimal.new("2"),
        size_unit: "L",
        label: "2L bottle",
        is_default: false
      }
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Controlcopypasta.Ingredients.CanonicalIngredient

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "brand_package_sizes" do
    field :package_type, :string
    field :size_value, :decimal
    field :size_unit, :string
    field :label, :string
    field :is_default, :boolean, default: false
    field :sort_order, :integer, default: 0

    belongs_to :canonical_ingredient, CanonicalIngredient

    timestamps()
  end

  @required_fields [:canonical_ingredient_id, :package_type, :size_value, :size_unit]
  @optional_fields [:label, :is_default, :sort_order]

  @valid_package_types ~w(can bottle box bag jar carton packet pouch stick tub container sleeve pack bar)
  @valid_size_units ~w(oz ml L g kg lb fl_oz cup tbsp tsp ct)

  @doc """
  Creates a changeset for a brand package size.
  """
  def changeset(package_size, attrs) do
    package_size
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:package_type, @valid_package_types)
    |> validate_inclusion(:size_unit, @valid_size_units)
    |> validate_number(:size_value, greater_than: 0)
    |> generate_label()
    |> unique_constraint([:canonical_ingredient_id, :package_type, :size_value, :size_unit])
  end

  defp generate_label(changeset) do
    if get_field(changeset, :label) do
      changeset
    else
      size_value = get_field(changeset, :size_value)
      size_unit = get_field(changeset, :size_unit)
      package_type = get_field(changeset, :package_type)

      if size_value && size_unit && package_type do
        # Format nicely: "12 oz can", "2L bottle"
        formatted_value = format_size_value(size_value)
        label = "#{formatted_value} #{size_unit} #{package_type}"
        put_change(changeset, :label, label)
      else
        changeset
      end
    end
  end

  defp format_size_value(decimal) do
    # Convert to float and format nicely (no trailing zeros)
    float = Decimal.to_float(decimal)

    if float == trunc(float) do
      Integer.to_string(trunc(float))
    else
      Float.to_string(float)
    end
  end

  @doc """
  Returns valid package types.
  """
  def valid_package_types, do: @valid_package_types

  @doc """
  Returns valid size units.
  """
  def valid_size_units, do: @valid_size_units
end
