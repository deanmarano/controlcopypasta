defmodule Controlcopypasta.Ingredients.PreStepGenerator do
  @moduledoc """
  Converts parsed preparations into actionable pre-steps (mise en place).

  Pre-steps are the preparation tasks that should be completed before cooking:
  - Bringing butter to room temperature
  - Dicing vegetables
  - Toasting nuts

  Each pre-step includes the action verb, target ingredient, estimated time,
  and suggested order (temperature-dependent items first, cutting last).
  """

  alias Controlcopypasta.Ingredients.TokenParser.ParsedIngredient
  alias Controlcopypasta.Ingredients.ReferenceData.Preparations

  defmodule PreStep do
    @moduledoc "A single preparation step to be done before cooking."

    defstruct [
      :action,              # Verb: "dice", "mince", "bring to room temperature"
      :target,              # Ingredient: "carrots", "butter"
      :quantity,            # Amount: 2.0
      :unit,                # Unit: "cup", "tbsp"
      :category,            # :cut, :cook, :temperature, :process
      :estimated_time_min,  # Time estimate in minutes
      :tool,                # Optional tool needed: "knife", "grater"
      :order_hint,          # Suggested order (lower = do first)
      :original_prep        # Original prep string from parsing
    ]

    @type t :: %__MODULE__{
            action: String.t(),
            target: String.t() | nil,
            quantity: float() | nil,
            unit: String.t() | nil,
            category: atom(),
            estimated_time_min: number() | nil,
            tool: String.t() | nil,
            order_hint: integer() | nil,
            original_prep: String.t()
          }
  end

  # Preparation metadata is now centralized in ReferenceData.Preparations

  @doc """
  Generates pre-steps from a parsed ingredient.

  Returns a list of PreStep structs, ordered by suggested prep order
  (temperature-dependent items first, cutting last).

  ## Examples

      iex> parsed = %ParsedIngredient{
      ...>   preparations: ["diced", "drained"],
      ...>   primary_ingredient: %{canonical_name: "tomatoes"},
      ...>   quantity: 2.0,
      ...>   unit: "cup"
      ...> }
      iex> PreStepGenerator.generate_pre_steps(parsed)
      [%PreStep{action: "drain", ...}, %PreStep{action: "dice", ...}]
  """
  def generate_pre_steps(%ParsedIngredient{preparations: preps} = parsed) when is_list(preps) do
    preps
    |> Enum.map(&prep_to_step(&1, parsed))
    |> Enum.reject(&is_nil/1)
    |> assign_order_hints()
  end

  def generate_pre_steps(_), do: []

  @doc """
  Returns the preparation metadata map for external use (e.g., API responses).
  """
  def preparations_metadata, do: Preparations.all_with_metadata()

  @doc """
  Checks if a preparation string has metadata defined.
  """
  def known_preparation?(prep) do
    Preparations.get_metadata(prep) != nil
  end

  # Convert a preparation string to a PreStep struct
  defp prep_to_step(prep, ingredient) do
    case Preparations.get_metadata(prep) do
      nil ->
        # Unknown preparation - still include it with defaults
        %PreStep{
          action: prep,
          target: get_target_name(ingredient),
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: :other,
          estimated_time_min: nil,
          tool: nil,
          original_prep: prep
        }

      meta ->
        %PreStep{
          action: meta.verb,
          target: get_target_name(ingredient),
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: meta.category,
          estimated_time_min: estimate_time(meta, ingredient),
          tool: meta[:tool],
          original_prep: prep
        }
    end
  end

  defp get_target_name(%{primary_ingredient: %{canonical_name: name}}) when is_binary(name), do: name
  defp get_target_name(%{primary_ingredient: %{name: name}}) when is_binary(name), do: name
  defp get_target_name(_), do: nil

  # Estimate time based on metadata and quantity
  defp estimate_time(%{time_min: time}, _ingredient), do: time

  defp estimate_time(%{time_per_cup: time_per_cup}, %{quantity: qty, unit: unit})
       when is_number(qty) do
    # Convert to cups for estimation (rough conversion)
    cups = case unit do
      "cup" -> qty
      "tbsp" -> qty / 16
      "tsp" -> qty / 48
      "oz" -> qty / 8
      "lb" -> qty * 2  # Rough: 1 lb ~ 2 cups for most vegetables
      _ -> qty  # Assume 1:1 for unknown units
    end

    max(1, round(cups * time_per_cup))
  end

  defp estimate_time(%{time_per_item: time_per_item}, %{quantity: qty})
       when is_number(qty) do
    max(1, round(qty * time_per_item))
  end

  defp estimate_time(_, _), do: nil

  # Order: temperature first (need time), then cook, then process, then cut (can do while cooking)
  defp assign_order_hints(steps) do
    steps
    |> Enum.sort_by(fn step ->
      {category_order(step.category), step.action}
    end)
    |> Enum.with_index(1)
    |> Enum.map(fn {step, idx} -> %{step | order_hint: idx} end)
  end

  defp category_order(:temperature), do: 0  # Room temp butter, thaw frozen items
  defp category_order(:cook), do: 1         # Pre-cook components
  defp category_order(:process), do: 2      # Drain, rinse, soak
  defp category_order(:cut), do: 3          # Chopping can happen during cooking
  defp category_order(_), do: 4

  @doc """
  Converts a PreStep to a map suitable for JSONB storage.
  """
  def to_map(%PreStep{} = step) do
    %{
      "action" => step.action,
      "target" => step.target,
      "quantity" => step.quantity,
      "unit" => step.unit,
      "category" => Atom.to_string(step.category),
      "estimated_time_min" => step.estimated_time_min,
      "tool" => step.tool,
      "order_hint" => step.order_hint
    }
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Map.new()
  end
end
