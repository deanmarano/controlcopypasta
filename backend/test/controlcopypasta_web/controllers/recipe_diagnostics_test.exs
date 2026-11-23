defmodule ControlcopypastaWeb.RecipeDiagnosticsTest do
  # Not async: toggling :admin_emails is global application state.
  use ControlcopypastaWeb.ConnCase, async: false

  import Controlcopypasta.RecipesFixtures

  setup :setup_authenticated_conn

  setup %{user: user} do
    previous = Application.get_env(:controlcopypasta, :admin_emails, [])
    on_exit(fn -> Application.put_env(:controlcopypasta, :admin_emails, previous) end)

    %{make_admin: fn -> Application.put_env(:controlcopypasta, :admin_emails, [user.email]) end}
  end

  defp ingredients(conn, recipe, query) do
    conn
    |> get(~p"/api/recipes/#{recipe.id}?#{query}")
    |> json_response(200)
    |> Map.fetch!("data")
    |> Map.fetch!("ingredients")
  end

  describe "GET /api/recipes/:id?include_diagnostics=true" do
    test "an admin gets diagnostics for every ingredient", %{
      conn: conn,
      user: user,
      make_admin: make_admin
    } do
      make_admin.()
      recipe = recipe_fixture(%{user: user})

      result = ingredients(conn, recipe, %{"include_diagnostics" => "true"})

      assert length(result) == 2

      for ingredient <- result do
        diag = ingredient["_diagnostics"]

        assert diag, "expected _diagnostics on #{inspect(ingredient["text"])}"
        assert is_binary(diag["tokens"])
        assert is_binary(diag["parser"])
        assert is_boolean(diag["drifted"])
        assert Map.has_key?(diag, "reparsed_canonical_name")
      end
    end

    test "a non-admin never gets diagnostics, even when asking", %{conn: conn, user: user} do
      recipe = recipe_fixture(%{user: user})

      result = ingredients(conn, recipe, %{"include_diagnostics" => "true"})

      assert Enum.all?(result, &is_nil(&1["_diagnostics"]))
    end

    test "an admin who does not ask does not get diagnostics", %{
      conn: conn,
      user: user,
      make_admin: make_admin
    } do
      make_admin.()
      recipe = recipe_fixture(%{user: user})

      result = ingredients(conn, recipe, %{})

      assert Enum.all?(result, &is_nil(&1["_diagnostics"]))
    end

    test "diagnostics are not persisted to the recipe", %{
      conn: conn,
      user: user,
      make_admin: make_admin
    } do
      make_admin.()
      recipe = recipe_fixture(%{user: user})

      _ = ingredients(conn, recipe, %{"include_diagnostics" => "true"})

      stored = Controlcopypasta.Recipes.get_recipe(recipe.id)
      assert Enum.all?(stored.ingredients, &is_nil(&1["_diagnostics"]))
    end
  end
end
