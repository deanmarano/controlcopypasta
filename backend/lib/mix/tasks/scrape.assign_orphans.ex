defmodule Mix.Tasks.Scrape.AssignOrphans do
  @moduledoc """
  Assigns orphan recipes (no user_id) to their domain accounts.

  Usage:
    mix scrape.assign_orphans [--domain <domain>]

  Examples:
    mix scrape.assign_orphans                      # Assign all orphan recipes
    mix scrape.assign_orphans --domain bonappetit.com  # Only bonappetit recipes
  """

  use Mix.Task

  import Ecto.Query
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Recipes.Recipe
  alias Controlcopypasta.Accounts.User

  @shortdoc "Assign orphan recipes to domain accounts"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _rest, _invalid} = OptionParser.parse(args, strict: [domain: :string])

    domain = opts[:domain]

    # Find orphan recipes
    query =
      Recipe
      |> where([r], is_nil(r.user_id))
      |> where([r], not is_nil(r.source_domain))

    query =
      if domain do
        # Match with or without www.
        where(query, [r], r.source_domain == ^domain or r.source_domain == ^"www.#{domain}")
      else
        query
      end

    orphans = Repo.all(query)

    if Enum.empty?(orphans) do
      Mix.shell().info("No orphan recipes found")
    else
      Mix.shell().info("Found #{length(orphans)} orphan recipe(s)")

      # Group by domain
      by_domain = Enum.group_by(orphans, & &1.source_domain)

      Enum.each(by_domain, fn {domain, recipes} ->
        user = get_or_create_domain_user(domain)
        Mix.shell().info("\nAssigning #{length(recipes)} recipes to #{user.email}")

        Enum.each(recipes, fn recipe ->
          recipe
          |> Ecto.Changeset.change(user_id: user.id)
          |> Repo.update!()

          Mix.shell().info("  ✓ #{recipe.title}")
        end)
      end)

      Mix.shell().info("\nDone!")
    end
  end

  defp get_or_create_domain_user(domain) do
    # Normalize domain (remove www. prefix)
    normalized = domain |> String.replace(~r/^www\./, "")
    email = "recipes@#{normalized}"

    case Repo.get_by(User, email: email) do
      nil ->
        {:ok, user} =
          %User{}
          |> Ecto.Changeset.change(email: email)
          |> Repo.insert()

        Mix.shell().info("Created domain account: #{email}")
        user

      user ->
        user
    end
  end
end
