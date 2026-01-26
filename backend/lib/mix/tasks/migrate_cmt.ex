defmodule Mix.Tasks.MigrateCmt do
  @moduledoc """
  Migrates recipes from Copy Me That by parsing their source URLs.

  Usage:
    mix migrate_cmt EMAIL              # Migrate all CMT recipes for user
    mix migrate_cmt EMAIL --limit 5    # Migrate first 5 recipes
    mix migrate_cmt EMAIL --dry-run    # Show what would be imported

  The CMT export should be placed at test/fixtures/cmt_export.json
  or set CMT_EXPORT_PATH environment variable.
  """
  use Mix.Task

  alias Controlcopypasta.{Accounts, Parser, Recipes}
  alias Controlcopypasta.Import.CmtFixture

  @shortdoc "Migrate recipes from Copy Me That"

  def run(args) do
    Application.ensure_all_started(:controlcopypasta)

    {opts, rest, _} =
      OptionParser.parse(args,
        switches: [limit: :integer, dry_run: :boolean, verbose: :boolean]
      )

    email = List.first(rest)

    unless email do
      Mix.shell().error("Usage: mix migrate_cmt EMAIL [--limit N] [--dry-run] [--verbose]")
      System.halt(1)
    end

    user = get_or_create_user(email)
    Mix.shell().info("Migrating recipes for user: #{user.email} (ID: #{user.id})")

    recipes = CmtFixture.with_urls()

    if recipes == [] do
      Mix.shell().error("""
      No CMT recipes with URLs found.

      To get started:
        1. Run the CMT scraper or place your export at test/fixtures/cmt_export.json
        2. Run: mix migrate_cmt #{email}
      """)

      System.halt(1)
    end

    limit = opts[:limit] || length(recipes)
    recipes = Enum.take(recipes, limit)

    Mix.shell().info("Found #{length(recipes)} recipes to migrate\n")

    if opts[:dry_run] do
      Mix.shell().info("DRY RUN - No recipes will be created\n")
    end

    results =
      recipes
      |> Enum.with_index(1)
      |> Enum.map(fn {cmt_recipe, idx} ->
        url = cmt_recipe["url"]
        name = cmt_recipe["name"]
        Mix.shell().info("[#{idx}/#{length(recipes)}] #{name || url}")

        if opts[:dry_run] do
          {:dry_run, name, url}
        else
          migrate_recipe(user, url, opts)
        end
      end)

    print_summary(results, opts[:dry_run])
  end

  defp get_or_create_user(email) do
    case Accounts.get_user_by_email(email) do
      nil ->
        Mix.shell().info("Creating user: #{email}")
        {:ok, user} = Accounts.create_user(%{email: email})
        user

      user ->
        user
    end
  end

  defp migrate_recipe(user, url, opts) do
    # Check if recipe already exists for this user with this URL
    case Recipes.get_recipe_by_source_url(user.id, url) do
      nil ->
        # Parse and create
        case Parser.parse_url(url) do
          {:ok, parsed} ->
            recipe_params = build_recipe_params(user, parsed)

            case Recipes.create_recipe(recipe_params) do
              {:ok, recipe} ->
                if opts[:verbose] do
                  Mix.shell().info("  ✓ Created: #{recipe.title}")
                else
                  Mix.shell().info("  ✓ #{recipe.title}")
                end

                {:ok, recipe.title, url}

              {:error, changeset} ->
                Mix.shell().info("  ✗ Failed to save: #{inspect(changeset.errors)}")
                {:error, url, changeset.errors}
            end

          {:error, reason} ->
            Mix.shell().info("  ✗ Failed to parse: #{inspect(reason)}")
            {:error, url, reason}
        end

      existing ->
        Mix.shell().info("  ~ Already exists: #{existing.title}")
        {:exists, existing.title, url}
    end
  end

  defp build_recipe_params(user, parsed) do
    %{
      user_id: user.id,
      title: parsed[:title],
      description: parsed[:description],
      source_url: parsed[:source_url],
      image_url: parsed[:image_url],
      prep_time_minutes: parsed[:prep_time_minutes],
      cook_time_minutes: parsed[:cook_time_minutes],
      total_time_minutes: parsed[:total_time_minutes],
      servings: parsed[:servings],
      ingredients: parsed[:ingredients] || [],
      instructions: parsed[:instructions] || []
    }
  end

  defp print_summary(results, dry_run) do
    created = Enum.count(results, &match?({:ok, _, _}, &1))
    exists = Enum.count(results, &match?({:exists, _, _}, &1))
    failed = Enum.count(results, &match?({:error, _, _}, &1))
    dry_run_count = Enum.count(results, &match?({:dry_run, _, _}, &1))

    Mix.shell().info("\n" <> String.duplicate("=", 50))
    Mix.shell().info("Migration Summary")
    Mix.shell().info(String.duplicate("=", 50))

    if dry_run do
      Mix.shell().info("Would migrate: #{dry_run_count}")
    else
      Mix.shell().info("Created:       #{created}")
      Mix.shell().info("Already exist: #{exists}")
      Mix.shell().info("Failed:        #{failed}")
    end

    if failed > 0 do
      Mix.shell().info("\nFailed recipes:")

      for {:error, url, reason} <- results do
        Mix.shell().info("  - #{url}: #{inspect(reason)}")
      end
    end
  end
end
