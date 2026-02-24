defmodule Controlcopypasta.Recipes.PrepList do
  @moduledoc """
  Generates a consolidated prep list from all recipe ingredients.

  Aggregates pre-steps across all ingredients in a recipe, groups them by
  category, deduplicates similar tasks, and provides time estimates.

  ## Example

      iex> recipe = Recipes.get_recipe!(id)
      iex> PrepList.generate(recipe)
      %{
        steps: [%{action: "soften", target: "butter", ...}, ...],
        by_category: %{temperature: [...], cut: [...]},
        total_time_min: 45
      }
  """

  alias Controlcopypasta.Ingredients.PreStepGenerator

  @category_labels %{
    temperature: "Temperature Prep",
    cook: "Pre-cooking",
    process: "Processing",
    cut: "Cutting & Chopping",
    other: "Other Prep"
  }

  @doc """
  Generates a prep list from a recipe's ingredients.

  ## Options

  - `:include_unknown` - Include prep steps for unknown preparations (default: true)

  ## Returns

  A map with:
  - `steps` - All prep steps, ordered by suggested sequence
  - `by_category` - Steps grouped by category
  - `total_time_min` - Estimated total prep time (sequential)
  - `parallel_time_min` - Estimated time if doing parallel prep (e.g., items coming to room temp while chopping)
  """
  def generate(recipe, opts \\ []) do
    include_unknown = Keyword.get(opts, :include_unknown, true)

    steps =
      recipe.ingredients
      |> extract_pre_steps()
      |> deduplicate_similar()
      |> maybe_filter_unknown(include_unknown)
      |> reassign_order_hints()

    by_category = group_by_category(steps)

    %{
      steps: steps,
      by_category: by_category,
      total_time_min: calculate_total_time(steps),
      parallel_time_min: calculate_parallel_time(by_category),
      category_labels: @category_labels
    }
  end

  @doc """
  Formats the prep list as a markdown checklist.

  ## Example

      iex> PrepList.format_as_checklist(prep_list)
      \"\"\"
      ## Before You Start (~25 min)

      ### Temperature Prep
      - [ ] Bring 4 tbsp butter to room temperature (30 min)

      ### Cutting & Chopping
      - [ ] Dice 2 cups carrots (4 min)
      - [ ] Mince 3 cloves garlic (2 min)
      \"\"\"
  """
  def format_as_checklist(%{by_category: by_category, total_time_min: total}) do
    header = "## Before You Start (~#{total || "?"} min)\n\n"

    body =
      [:temperature, :cook, :process, :cut, :other]
      |> Enum.map(fn cat ->
        steps = Map.get(by_category, cat, [])
        format_category(cat, steps)
      end)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n")

    header <> body
  end

  defp format_category(_cat, []), do: ""

  defp format_category(cat, steps) do
    label = Map.get(@category_labels, cat, "Other")
    header = "### #{label}\n"

    items =
      steps
      |> Enum.map(&format_step/1)
      |> Enum.join("\n")

    header <> items <> "\n"
  end

  defp format_step(step) do
    target = step["target"] || "ingredient"
    qty_unit = format_quantity(step["quantity"], step["unit"])
    time = if step["estimated_time_min"], do: " (~#{step["estimated_time_min"]} min)", else: ""

    "- [ ] #{String.capitalize(step["action"])} #{qty_unit}#{target}#{time}"
  end

  defp format_quantity(nil, _), do: ""
  defp format_quantity(qty, nil), do: "#{format_number(qty)} "
  defp format_quantity(qty, unit), do: "#{format_number(qty)} #{unit} "

  defp format_number(n) when is_float(n) do
    if n == trunc(n), do: "#{trunc(n)}", else: "#{n}"
  end

  defp format_number(n), do: "#{n}"

  # Extract pre_steps from ingredients, handling both parsed structs and JSONB maps
  defp extract_pre_steps(ingredients) when is_list(ingredients) do
    ingredients
    |> Enum.flat_map(&extract_ingredient_pre_steps/1)
  end

  defp extract_ingredient_pre_steps(%{"pre_steps" => steps}) when is_list(steps), do: steps
  defp extract_ingredient_pre_steps(%{pre_steps: steps}) when is_list(steps), do: steps

  # For parsed ingredients without pre_steps, generate them
  defp extract_ingredient_pre_steps(
         %Controlcopypasta.Ingredients.TokenParser.ParsedIngredient{} = parsed
       ) do
    parsed
    |> PreStepGenerator.generate_pre_steps()
    |> Enum.map(&PreStepGenerator.to_map/1)
  end

  defp extract_ingredient_pre_steps(_), do: []

  # Deduplicate similar steps (e.g., "dice onion" appearing twice)
  defp deduplicate_similar(steps) do
    steps
    |> Enum.group_by(fn step ->
      {step["action"], step["target"]}
    end)
    |> Enum.map(fn {_key, group} ->
      # Merge quantities for the same action/target
      merged =
        Enum.reduce(group, fn step, acc ->
          merge_step(acc, step)
        end)

      merged
    end)
  end

  defp merge_step(step1, step2) do
    # Add quantities if both have them and same unit
    new_qty =
      case {step1["quantity"], step2["quantity"], step1["unit"], step2["unit"]} do
        {q1, q2, u, u} when is_number(q1) and is_number(q2) -> q1 + q2
        {q1, _, _, _} when is_number(q1) -> q1
        {_, q2, _, _} when is_number(q2) -> q2
        _ -> nil
      end

    # Recalculate time estimate if we merged quantities
    new_time =
      if new_qty && new_qty != step1["quantity"] do
        recalculate_time(step1, new_qty)
      else
        step1["estimated_time_min"]
      end

    %{step1 | "quantity" => new_qty, "estimated_time_min" => new_time}
  end

  defp recalculate_time(step, new_qty) do
    # Simple linear scaling from original estimate
    case {step["quantity"], step["estimated_time_min"]} do
      {old_qty, time} when is_number(old_qty) and old_qty > 0 and is_number(time) ->
        round(time * new_qty / old_qty)

      _ ->
        step["estimated_time_min"]
    end
  end

  defp maybe_filter_unknown(steps, true), do: steps

  defp maybe_filter_unknown(steps, false) do
    Enum.reject(steps, &(&1["category"] == "other"))
  end

  defp reassign_order_hints(steps) do
    steps
    |> Enum.sort_by(&category_sort_key/1)
    |> Enum.with_index(1)
    |> Enum.map(fn {step, idx} -> Map.put(step, "order_hint", idx) end)
  end

  defp category_sort_key(%{"category" => "temperature"}), do: 0
  defp category_sort_key(%{"category" => "cook"}), do: 1
  defp category_sort_key(%{"category" => "process"}), do: 2
  defp category_sort_key(%{"category" => "cut"}), do: 3
  defp category_sort_key(_), do: 4

  defp group_by_category(steps) do
    steps
    |> Enum.group_by(&String.to_atom(&1["category"]))
  end

  defp calculate_total_time(steps) do
    steps
    |> Enum.map(&(&1["estimated_time_min"] || 0))
    |> Enum.sum()
    |> case do
      0 -> nil
      sum -> sum
    end
  end

  # Calculate parallel time: temperature can run while other work happens
  defp calculate_parallel_time(by_category) do
    temp_time =
      by_category
      |> Map.get(:temperature, [])
      |> Enum.map(&(&1["estimated_time_min"] || 0))
      |> Enum.max(fn -> 0 end)

    other_time =
      [:cook, :process, :cut, :other]
      |> Enum.flat_map(&Map.get(by_category, &1, []))
      |> Enum.map(&(&1["estimated_time_min"] || 0))
      |> Enum.sum()

    # Temperature happens in parallel with other work
    max(temp_time, other_time)
    |> case do
      0 -> nil
      time -> time
    end
  end
end
