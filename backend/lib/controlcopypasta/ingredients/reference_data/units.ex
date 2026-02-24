defmodule Controlcopypasta.Ingredients.ReferenceData.Units do
  @moduledoc """
  Canonical unit definitions and normalization.

  Single source of truth for:
  - Unit recognition and classification
  - Unit name normalization
  - Unit type categorization (volume, weight, count)
  """

  # Canonical unit names and their aliases
  # Key = canonical form, Value = list of aliases
  @unit_definitions %{
    # Volume units
    "tbsp" => ~w(tablespoons tablespoon tbsp tbs tb),
    "tsp" => ~w(teaspoons teaspoon tsp ts),
    "cup" => ~w(cups cup c),
    "fl_oz" => ~w(fluid\ ounces fluid\ ounce fl\ oz),
    "pint" => ~w(pints pint pt),
    "quart" => ~w(quarts quart qt),
    "gallon" => ~w(gallons gallon gal),
    "l" => ~w(liters liter litres litre l),
    "ml" => ~w(milliliters milliliter ml),

    # Weight units
    "oz" => ~w(ounces ounce oz),
    "lb" => ~w(pounds pound lbs lb),
    "g" => ~w(grams gram g),
    "kg" => ~w(kilograms kilogram kg),

    # Count units
    "pinch" => ~w(pinches pinch),
    "dash" => ~w(dashes dash),
    "bunch" => ~w(bunches bunch),
    "sprig" => ~w(sprigs sprig),
    "clove" => ~w(cloves clove),
    "slice" => ~w(slices slice),
    "piece" => ~w(pieces piece),
    "head" => ~w(heads head),
    "stalk" => ~w(stalks stalk),
    "sheet" => ~w(sheets sheet),
    "leaf" => ~w(leaves leaf),

    # Container units
    "can" => ~w(cans can),
    "jar" => ~w(jars jar),
    "bottle" => ~w(bottles bottle),
    "package" => ~w(packages package pkg),
    "bag" => ~w(bags bag),
    "box" => ~w(boxes box),
    "carton" => ~w(cartons carton),
    "container" => ~w(containers container),

    # Whole items
    "stick" => ~w(sticks stick)
  }

  # Unit categories
  @volume_units ~w(tbsp tsp cup fl_oz pint quart gallon l ml)
  @weight_units ~w(oz lb g kg)
  @count_units ~w(pinch dash bunch sprig clove slice piece head stalk sheet leaf stick)
  @container_units ~w(can jar bottle package bag box carton container)

  # Build reverse lookup map at compile time
  @unit_aliases @unit_definitions
                |> Enum.flat_map(fn {canonical, aliases} ->
                  Enum.map(aliases, fn alias -> {String.downcase(alias), canonical} end)
                end)
                |> Map.new()

  # All valid unit strings (for tokenizer)
  @all_units @unit_definitions
             |> Enum.flat_map(fn {_canonical, aliases} -> aliases end)
             # Longer units first for matching
             |> Enum.sort_by(&(-String.length(&1)))

  @doc """
  Returns all unit strings, sorted longest-first for tokenization.
  """
  def all_units, do: @all_units

  @doc """
  Normalizes a unit string to its canonical form.

  Returns the canonical unit name, or the lowercased original if not recognized.

  ## Examples

      iex> Units.normalize("tablespoons")
      "tbsp"

      iex> Units.normalize("oz")
      "oz"

      iex> Units.normalize("unknown")
      "unknown"
  """
  def normalize(nil), do: nil

  def normalize(unit) when is_binary(unit) do
    Map.get(@unit_aliases, String.downcase(unit), String.downcase(unit))
  end

  @doc """
  Checks if a string is a recognized unit.

  ## Examples

      iex> Units.is_unit?("cup")
      true

      iex> Units.is_unit?("flour")
      false
  """
  def is_unit?(nil), do: false

  def is_unit?(text) when is_binary(text) do
    Map.has_key?(@unit_aliases, String.downcase(text))
  end

  @doc """
  Returns the category of a unit.

  Categories: :volume, :weight, :count, :container, :unknown

  ## Examples

      iex> Units.unit_type("cup")
      :volume

      iex> Units.unit_type("lb")
      :weight

      iex> Units.unit_type("clove")
      :count
  """
  def unit_type(nil), do: :unknown

  def unit_type(unit) when is_binary(unit) do
    canonical = normalize(unit)

    cond do
      canonical in @volume_units -> :volume
      canonical in @weight_units -> :weight
      canonical in @count_units -> :count
      canonical in @container_units -> :container
      true -> :unknown
    end
  end

  @doc """
  Checks if a unit is a weight unit.
  """
  def weight_unit?(unit), do: unit_type(unit) == :weight

  @doc """
  Checks if a unit is a volume unit.
  """
  def volume_unit?(unit), do: unit_type(unit) == :volume

  @doc """
  Checks if a unit is a count unit.
  """
  def count_unit?(unit), do: unit_type(unit) == :count

  @doc """
  Checks if a unit is a container unit.
  """
  def container_unit?(unit), do: unit_type(unit) == :container

  @doc """
  Returns all container type words (for tokenizer container detection).
  """
  def container_types do
    ~w(can cans jar jars bottle bottles bag bags box boxes package packages pkg container containers carton cartons)
  end
end
