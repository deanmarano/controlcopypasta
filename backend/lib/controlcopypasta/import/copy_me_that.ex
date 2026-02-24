defmodule Controlcopypasta.Import.CopyMeThat do
  @moduledoc """
  Imports recipes from Copy Me That export or scraping.

  Copy Me That provides recipe data in their web interface. This module
  can parse exported data or scrape recipes from a logged-in session.
  """

  alias Controlcopypasta.Recipes

  @doc """
  Imports recipes from a Copy Me That JSON export.

  Expected format (array of recipe objects):
  [
    {
      "name": "Recipe Title",
      "description": "Recipe description",
      "url": "https://original-source.com/recipe",
      "image": "https://example.com/image.jpg",
      "ingredients": ["1 cup flour", "2 eggs"],
      "instructions": "Step 1. Do this.\\nStep 2. Do that.",
      "notes": "My notes",
      "tags": ["dinner", "quick"],
      "prepTime": "15 mins",
      "cookTime": "30 mins",
      "totalTime": "45 mins",
      "yield": "4 servings"
    }
  ]
  """
  def import_json(json_string, user_id) when is_binary(json_string) do
    with {:ok, recipes} <- Jason.decode(json_string) do
      import_recipes(recipes, user_id)
    end
  end

  def import_json(recipes, user_id) when is_list(recipes) do
    import_recipes(recipes, user_id)
  end

  defp import_recipes(recipes, user_id) do
    results =
      Enum.map(recipes, fn recipe ->
        attrs = normalize_recipe(recipe, user_id)

        case Recipes.create_recipe(attrs) do
          {:ok, created} -> {:ok, created}
          {:error, changeset} -> {:error, recipe["name"], changeset}
        end
      end)

    successful = Enum.filter(results, &match?({:ok, _}, &1))
    failed = Enum.filter(results, &match?({:error, _, _}, &1))

    {:ok,
     %{
       imported: length(successful),
       failed: length(failed),
       errors: Enum.map(failed, fn {:error, name, changeset} -> {name, changeset} end)
     }}
  end

  defp normalize_recipe(recipe, user_id) do
    %{
      user_id: user_id,
      title: recipe["name"] || "Untitled Recipe",
      description: recipe["description"],
      source_url: recipe["url"],
      image_url: recipe["image"],
      ingredients: normalize_ingredients(recipe["ingredients"]),
      instructions: normalize_instructions(recipe["instructions"]),
      notes: recipe["notes"],
      prep_time_minutes: parse_time(recipe["prepTime"]),
      cook_time_minutes: parse_time(recipe["cookTime"]),
      total_time_minutes: parse_time(recipe["totalTime"]),
      servings: recipe["yield"],
      tag_ids: get_or_create_tags(recipe["tags"] || [])
    }
  end

  defp normalize_ingredients(nil), do: []

  defp normalize_ingredients(ingredients) when is_binary(ingredients) do
    ingredients
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&%{"text" => &1, "group" => nil})
  end

  defp normalize_ingredients(ingredients) when is_list(ingredients) do
    Enum.map(ingredients, fn
      ingredient when is_binary(ingredient) ->
        %{"text" => String.trim(ingredient), "group" => nil}

      %{"text" => _} = ingredient ->
        ingredient

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp normalize_instructions(nil), do: []

  defp normalize_instructions(instructions) when is_binary(instructions) do
    instructions
    |> String.split(~r/\n+/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.with_index(1)
    |> Enum.map(fn {text, step} ->
      # Remove step prefixes like "Step 1." or "1."
      clean_text = String.replace(text, ~r/^(Step\s*)?\d+[\.\)]\s*/i, "")
      %{"step" => step, "text" => clean_text}
    end)
  end

  defp normalize_instructions(instructions) when is_list(instructions) do
    instructions
    |> Enum.with_index(1)
    |> Enum.map(fn
      {instruction, step} when is_binary(instruction) ->
        %{"step" => step, "text" => String.trim(instruction)}

      {%{"text" => _text} = instruction, step} ->
        Map.put(instruction, "step", step)

      _ ->
        nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp parse_time(nil), do: nil
  defp parse_time(time) when is_integer(time), do: time

  defp parse_time(time) when is_binary(time) do
    cond do
      # "1 hour 30 mins" or "1h 30m" - must check this FIRST
      String.match?(time, ~r/(\d+)\s*h.*?(\d+)\s*m/i) ->
        case Regex.run(~r/(\d+)\s*h.*?(\d+)\s*m/i, time) do
          [_, hours, minutes | _] ->
            String.to_integer(hours) * 60 + String.to_integer(minutes)

          _ ->
            nil
        end

      # "1 hour", "1 hr", "1h" (hours only)
      String.match?(time, ~r/(\d+)\s*h(our|r)?/i) ->
        case Regex.run(~r/(\d+)\s*h(our|r)?/i, time) do
          [_, hours | _] -> String.to_integer(hours) * 60
          _ -> nil
        end

      # "45 mins", "45 minutes", "45m" (minutes only)
      String.match?(time, ~r/(\d+)\s*m(in)?/i) ->
        case Regex.run(~r/(\d+)\s*m(in)?/i, time) do
          [_, minutes | _] -> String.to_integer(minutes)
          _ -> nil
        end

      true ->
        nil
    end
  end

  defp get_or_create_tags(tags) when is_list(tags) do
    tags
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn name ->
      case Recipes.get_or_create_tag(name) do
        {:ok, tag} -> tag.id
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
