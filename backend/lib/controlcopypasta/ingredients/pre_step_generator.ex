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

  # Preparation metadata: verb, category, tool, timing
  # Time estimates are rough and depend on quantity
  @preparations_with_metadata %{
    # Cutting preparations
    "diced" => %{verb: "dice", category: :cut, tool: "knife", time_per_cup: 2},
    "minced" => %{verb: "mince", category: :cut, tool: "knife", time_per_cup: 3},
    "julienned" => %{verb: "julienne", category: :cut, tool: "knife", time_per_cup: 5},
    "chopped" => %{verb: "chop", category: :cut, tool: "knife", time_per_cup: 1},
    "finely chopped" => %{verb: "finely chop", category: :cut, tool: "knife", time_per_cup: 2},
    "roughly chopped" => %{verb: "roughly chop", category: :cut, tool: "knife", time_per_cup: 1},
    "sliced" => %{verb: "slice", category: :cut, tool: "knife", time_per_cup: 1},
    "thinly sliced" => %{verb: "thinly slice", category: :cut, tool: "knife", time_per_cup: 2},
    "grated" => %{verb: "grate", category: :cut, tool: "grater", time_per_cup: 2},
    "shredded" => %{verb: "shred", category: :cut, tool: "grater", time_per_cup: 3},
    "cubed" => %{verb: "cube", category: :cut, tool: "knife", time_per_cup: 2},
    "halved" => %{verb: "halve", category: :cut, tool: "knife", time_per_item: 0.25},
    "quartered" => %{verb: "quarter", category: :cut, tool: "knife", time_per_item: 0.5},
    "crushed" => %{verb: "crush", category: :cut, tool: "knife", time_per_item: 0.25},

    # Temperature/State preparations
    "room temperature" => %{verb: "bring to room temperature", category: :temperature, time_min: 30},
    "softened" => %{verb: "soften", category: :temperature, time_min: 30},
    "melted" => %{verb: "melt", category: :temperature, time_min: 2},
    "chilled" => %{verb: "chill", category: :temperature, time_min: 60},
    "thawed" => %{verb: "thaw", category: :temperature, time_min: 120},
    "frozen" => %{verb: "freeze", category: :temperature, time_min: 120},
    "warmed" => %{verb: "warm", category: :temperature, time_min: 2},

    # Pre-cooking preparations
    "cooked" => %{verb: "cook", category: :cook, time_min: 15},
    "toasted" => %{verb: "toast", category: :cook, time_min: 5},
    "roasted" => %{verb: "roast", category: :cook, time_min: 30},
    "blanched" => %{verb: "blanch", category: :cook, time_min: 3},
    "sauteed" => %{verb: "saute", category: :cook, time_min: 5},
    "sautéed" => %{verb: "saute", category: :cook, time_min: 5},
    "fried" => %{verb: "fry", category: :cook, time_min: 10},
    "boiled" => %{verb: "boil", category: :cook, time_min: 10},
    "steamed" => %{verb: "steam", category: :cook, time_min: 10},
    "grilled" => %{verb: "grill", category: :cook, time_min: 15},
    "hard-boiled" => %{verb: "hard-boil", category: :cook, time_min: 12},
    "poached" => %{verb: "poach", category: :cook, time_min: 5},
    "caramelized" => %{verb: "caramelize", category: :cook, time_min: 15},

    # Processing preparations
    "drained" => %{verb: "drain", category: :process, time_min: 1},
    "rinsed" => %{verb: "rinse", category: :process, time_min: 1},
    "soaked" => %{verb: "soak", category: :process, time_min: 30},
    "dried" => %{verb: "dry", category: :process, time_min: 5},
    "peeled" => %{verb: "peel", category: :process, time_per_item: 0.5},
    "seeded" => %{verb: "seed", category: :process, time_per_item: 1},
    "cored" => %{verb: "core", category: :process, time_per_item: 0.5},
    "deveined" => %{verb: "devein", category: :process, time_per_item: 0.5},
    "pitted" => %{verb: "pit", category: :process, time_per_item: 0.25},
    "trimmed" => %{verb: "trim", category: :process, time_per_item: 0.25},
    "cleaned" => %{verb: "clean", category: :process, time_min: 2},
    "washed" => %{verb: "wash", category: :process, time_min: 1},
    "patted dry" => %{verb: "pat dry", category: :process, time_min: 1},
    "squeezed" => %{verb: "squeeze", category: :process, time_per_item: 0.5},
    "zested" => %{verb: "zest", category: :process, tool: "zester", time_per_item: 1},
    "juiced" => %{verb: "juice", category: :process, tool: "juicer", time_per_item: 0.5},
    "beaten" => %{verb: "beat", category: :process, tool: "whisk", time_min: 2},
    "whisked" => %{verb: "whisk", category: :process, tool: "whisk", time_min: 1},
    "separated" => %{verb: "separate", category: :process, time_per_item: 0.5},
    "sifted" => %{verb: "sift", category: :process, tool: "sifter", time_min: 1}
  }

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
  def preparations_metadata, do: @preparations_with_metadata

  @doc """
  Checks if a preparation string has metadata defined.
  """
  def known_preparation?(prep) do
    Map.has_key?(@preparations_with_metadata, String.downcase(prep))
  end

  # Convert a preparation string to a PreStep struct
  defp prep_to_step(prep, ingredient) do
    normalized = String.downcase(prep)

    case Map.get(@preparations_with_metadata, normalized) do
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
