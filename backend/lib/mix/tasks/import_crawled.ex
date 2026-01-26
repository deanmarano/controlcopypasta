defmodule Mix.Tasks.ImportCrawled do
  @moduledoc """
  Imports crawled recipes from a JSON file into the database.

  Usage:
    mix import_crawled <json_file> [--domain]

  Options:
    --domain  Use domain accounts (recipes@<domain>) instead of a user account

  Example:
    mix import_crawled ../scripts/bonappetit-recipes.json --domain
  """

  use Mix.Task

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Accounts.User
  alias Controlcopypasta.Recipes

  @shortdoc "Imports crawled recipes from a JSON file"

  def run([json_file, "--domain"]) do
    Mix.Task.run("app.start")
    import_with_domain_accounts(json_file)
  end

  def run([json_file, user_email]) do
    Mix.Task.run("app.start")

    # Find user
    user = Accounts.get_user_by_email(user_email)

    unless user do
      Mix.shell().error("User not found: #{user_email}")
      System.halt(1)
    end

    import_recipes(json_file, fn _recipe_data -> user end)
  end

  def run([json_file]) do
    # Default to domain accounts
    run([json_file, "--domain"])
  end

  def run(_) do
    Mix.shell().error("Usage: mix import_crawled <json_file> [--domain | <user_email>]")
    System.halt(1)
  end

  defp import_with_domain_accounts(json_file) do
    import_recipes(json_file, fn recipe_data ->
      domain = recipe_data["source_domain"] || "unknown"
      get_or_create_domain_user(domain)
    end)
  end

  defp get_or_create_domain_user(domain) do
    # Normalize domain (remove www. prefix for email)
    normalized = domain |> String.replace(~r/^www\./, "")
    email = "recipes@#{normalized}"

    case Repo.get_by(User, email: email) do
      nil ->
        {:ok, user} = %User{}
        |> Ecto.Changeset.change(email: email)
        |> Repo.insert()
        Mix.shell().info("Created domain account: #{email}")
        user
      user ->
        user
    end
  end

  defp import_recipes(json_file, get_user_fn) do
    case File.read(json_file) do
      {:ok, content} ->
        recipes = Jason.decode!(content)
        Mix.shell().info("Found #{length(recipes)} recipes to import")

        results = Enum.map(recipes, fn recipe_data ->
          user = get_user_fn.(recipe_data)
          import_recipe(recipe_data, user)
        end)

        created = Enum.count(results, &(&1 == :created))
        exists = Enum.count(results, &(&1 == :exists))
        failed = Enum.count(results, &(&1 == :failed))

        Mix.shell().info("\nImport complete:")
        Mix.shell().info("  Created: #{created}")
        Mix.shell().info("  Already exist: #{exists}")
        Mix.shell().info("  Failed: #{failed}")

      {:error, reason} ->
        Mix.shell().error("Could not read file: #{reason}")
        System.halt(1)
    end
  end

  defp import_recipe(recipe_data, user) do
    source_url = recipe_data["source_url"]

    # Check if recipe already exists
    case Recipes.get_recipe_by_source_url(user.id, source_url) do
      nil ->
        attrs = %{
          "title" => recipe_data["title"],
          "description" => recipe_data["description"],
          "source_url" => source_url,
          "source_domain" => recipe_data["source_domain"],
          "image_url" => recipe_data["image_url"],
          "ingredients" => recipe_data["ingredients"] || [],
          "instructions" => recipe_data["instructions"] || [],
          "prep_time_minutes" => recipe_data["prep_time_minutes"],
          "cook_time_minutes" => recipe_data["cook_time_minutes"],
          "total_time_minutes" => recipe_data["total_time_minutes"],
          "servings" => recipe_data["servings"],
          "notes" => recipe_data["notes"],
          "user_id" => user.id
        }

        case Recipes.create_recipe(attrs) do
          {:ok, recipe} ->
            Mix.shell().info("✓ Created: #{recipe.title}")
            :created

          {:error, changeset} ->
            Mix.shell().error("✗ Failed: #{recipe_data["title"]} - #{inspect(changeset.errors)}")
            :failed
        end

      _existing ->
        Mix.shell().info("○ Exists: #{recipe_data["title"]}")
        :exists
    end
  end
end
