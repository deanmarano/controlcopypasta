defmodule Controlcopypasta.Import.CmtFixture do
  @moduledoc """
  Loads Copy Me That export data for parser comparison testing.

  Place your CMT export JSON file at:
    test/fixtures/cmt_export.json

  Or set the CMT_EXPORT_PATH environment variable.
  """

  @default_path "test/fixtures/cmt_export.json"

  @doc """
  Loads CMT recipes from the export file.
  Returns {:ok, recipes} or {:error, reason}.
  """
  def load do
    path = System.get_env("CMT_EXPORT_PATH") || @default_path

    case File.read(path) do
      {:ok, content} ->
        case Jason.decode(content) do
          {:ok, recipes} when is_list(recipes) ->
            {:ok, recipes}

          {:ok, %{"recipes" => recipes}} when is_list(recipes) ->
            {:ok, recipes}

          {:ok, _} ->
            {:error, "Expected JSON array or object with 'recipes' key"}

          {:error, reason} ->
            {:error, "Invalid JSON: #{inspect(reason)}"}
        end

      {:error, :enoent} ->
        {:error, "CMT export file not found at #{path}"}

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  @doc """
  Loads CMT recipes, returning empty list on error.
  Useful for tests that should skip gracefully if no fixture exists.
  """
  def load! do
    case load() do
      {:ok, recipes} -> recipes
      {:error, _} -> []
    end
  end

  @doc """
  Returns recipes that have a valid source URL.
  """
  def with_urls do
    load!()
    |> Enum.filter(fn recipe ->
      url = recipe["url"] || recipe["source_url"]
      url && url != "" && String.starts_with?(url, "http")
    end)
  end

  @doc """
  Saves sample CMT format to help users understand the expected structure.
  """
  def save_sample(path \\ "test/fixtures/cmt_export_sample.json") do
    sample = [
      %{
        "name" => "Sample Recipe",
        "url" => "https://example.com/recipe",
        "description" => "A sample recipe description",
        "image" => "https://example.com/image.jpg",
        "ingredients" => [
          "1 cup all-purpose flour",
          "2 large eggs",
          "1/2 cup sugar"
        ],
        "instructions" =>
          "Step 1. Preheat oven to 350°F.\nStep 2. Mix dry ingredients.\nStep 3. Add wet ingredients and stir.",
        "prepTime" => "15 mins",
        "cookTime" => "30 mins",
        "totalTime" => "45 mins",
        "yield" => "4 servings",
        "tags" => ["dessert", "easy"]
      }
    ]

    File.mkdir_p!(Path.dirname(path))
    File.write!(path, Jason.encode!(sample, pretty: true))
    {:ok, path}
  end
end
