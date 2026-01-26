defmodule Controlcopypasta.Parser.JsonLd do
  @moduledoc """
  Extracts Schema.org Recipe data from JSON-LD structured data.
  """

  def extract(html) when is_binary(html) do
    with {:ok, document} <- Floki.parse_document(html),
         json_ld_scripts <- Floki.find(document, "script[type='application/ld+json']"),
         {:ok, recipe} <- find_recipe(json_ld_scripts) do
      {:ok, normalize_recipe(recipe)}
    end
  end

  defp find_recipe([]), do: {:error, :no_json_ld}

  defp find_recipe([script | rest]) do
    case extract_recipe_from_script(script) do
      {:ok, recipe} -> {:ok, recipe}
      {:error, _} -> find_recipe(rest)
    end
  end

  defp extract_recipe_from_script(script) do
    # Floki.text() doesn't work for script tags, need to get raw content
    text = get_script_content(script)

    with {:ok, json} <- Jason.decode(text),
         {:ok, recipe} <- find_recipe_in_json(json) do
      {:ok, recipe}
    end
  end

  defp get_script_content({"script", _attrs, children}) do
    children
    |> Enum.map_join("", fn
      text when is_binary(text) -> text
      _ -> ""
    end)
    |> String.trim()
  end

  defp get_script_content(_), do: ""

  defp find_recipe_in_json(%{"@type" => "Recipe"} = recipe), do: {:ok, recipe}
  defp find_recipe_in_json(%{"@type" => ["Recipe" | _]} = recipe), do: {:ok, recipe}

  defp find_recipe_in_json(%{"@type" => types} = recipe) when is_list(types) do
    if "Recipe" in types, do: {:ok, recipe}, else: {:error, :not_recipe}
  end

  defp find_recipe_in_json(%{"@graph" => graph}) when is_list(graph) do
    case Enum.find(graph, &is_recipe?/1) do
      nil -> {:error, :no_recipe_in_graph}
      recipe -> {:ok, recipe}
    end
  end

  defp find_recipe_in_json(list) when is_list(list) do
    case Enum.find(list, &is_recipe?/1) do
      nil -> {:error, :no_recipe_in_list}
      recipe -> {:ok, recipe}
    end
  end

  defp find_recipe_in_json(_), do: {:error, :not_recipe}

  defp is_recipe?(%{"@type" => "Recipe"}), do: true
  defp is_recipe?(%{"@type" => ["Recipe" | _]}), do: true

  defp is_recipe?(%{"@type" => types}) when is_list(types) do
    "Recipe" in types
  end

  defp is_recipe?(_), do: false

  defp normalize_recipe(recipe) do
    %{
      title: get_string(recipe, "name"),
      description: get_string(recipe, "description"),
      image_url: get_image_url(recipe),
      ingredients: normalize_ingredients(recipe),
      instructions: normalize_instructions(recipe),
      prep_time_minutes: parse_duration(recipe["prepTime"]),
      cook_time_minutes: parse_duration(recipe["cookTime"]),
      total_time_minutes: parse_duration(recipe["totalTime"]),
      servings: get_servings(recipe)
    }
  end

  defp get_string(map, key) do
    case Map.get(map, key) do
      nil -> nil
      value when is_binary(value) -> String.trim(value)
      _ -> nil
    end
  end

  defp get_image_url(%{"image" => image}) when is_binary(image), do: image

  defp get_image_url(%{"image" => %{"url" => url}}) when is_binary(url), do: url

  defp get_image_url(%{"image" => [first | _]}) when is_binary(first), do: first

  defp get_image_url(%{"image" => [%{"url" => url} | _]}) when is_binary(url), do: url

  defp get_image_url(_), do: nil

  defp normalize_ingredients(%{"recipeIngredient" => ingredients}) when is_list(ingredients) do
    ingredients
    |> Enum.with_index()
    |> Enum.map(fn {text, _index} ->
      %{"text" => normalize_text(text), "group" => nil}
    end)
  end

  defp normalize_ingredients(_), do: []

  defp normalize_instructions(%{"recipeInstructions" => instructions}) when is_list(instructions) do
    instructions
    |> Enum.with_index(1)
    |> Enum.flat_map(&normalize_instruction/1)
  end

  defp normalize_instructions(_), do: []

  defp normalize_instruction({%{"@type" => "HowToStep", "text" => text}, step}) do
    [%{"step" => step, "text" => normalize_text(text)}]
  end

  defp normalize_instruction({%{"text" => text}, step}) do
    [%{"step" => step, "text" => normalize_text(text)}]
  end

  defp normalize_instruction({%{"@type" => "HowToSection", "itemListElement" => items}, _step})
       when is_list(items) do
    items
    |> Enum.with_index(1)
    |> Enum.flat_map(&normalize_instruction/1)
  end

  defp normalize_instruction({text, step}) when is_binary(text) do
    [%{"step" => step, "text" => normalize_text(text)}]
  end

  defp normalize_instruction(_), do: []

  defp normalize_text(text) when is_binary(text) do
    text
    |> String.replace(~r/<[^>]*>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp normalize_text(_), do: ""

  defp parse_duration(nil), do: nil

  defp parse_duration(duration) when is_binary(duration) do
    # Parse ISO 8601 duration (e.g., PT30M, PT1H30M)
    case Regex.run(~r/PT(?:(\d+)H)?(?:(\d+)M)?/, duration) do
      [_, hours, minutes] ->
        h = parse_int(hours, 0)
        m = parse_int(minutes, 0)
        h * 60 + m

      [_, "", minutes] ->
        parse_int(minutes, 0)

      [_, hours] ->
        parse_int(hours, 0) * 60

      _ ->
        nil
    end
  end

  defp parse_duration(_), do: nil

  defp parse_int("", default), do: default
  defp parse_int(nil, default), do: default

  defp parse_int(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} -> int
      :error -> default
    end
  end

  defp get_servings(%{"recipeYield" => yield}) when is_binary(yield), do: yield
  defp get_servings(%{"recipeYield" => [yield | _]}) when is_binary(yield), do: yield
  defp get_servings(%{"recipeYield" => yield}) when is_integer(yield), do: "#{yield}"
  defp get_servings(_), do: nil
end
