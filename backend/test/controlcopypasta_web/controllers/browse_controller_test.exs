defmodule ControlcopypastaWeb.BrowseControllerTest do
  use ControlcopypastaWeb.ConnCase, async: true

  import Controlcopypasta.RecipesFixtures

  setup :setup_authenticated_conn

  describe "GET /api/browse/search" do
    test "finds recipes from any source domain by title", %{conn: conn} do
      recipe_fixture(%{title: "Weeknight Lasagna", source_domain: "example.com"})
      recipe_fixture(%{title: "Lasagna Soup", source_domain: "other.example"})
      recipe_fixture(%{title: "Chocolate Cake", source_domain: "example.com"})

      response = conn |> get(~p"/api/browse/search?q=lasagna") |> json_response(200)

      assert response["total"] == 2
      titles = Enum.map(response["data"], & &1["title"])
      assert Enum.sort(titles) == ["Lasagna Soup", "Weeknight Lasagna"]
    end

    test "matches on description too", %{conn: conn} do
      recipe_fixture(%{
        title: "Sunday Sauce",
        description: "A slow-cooked ragu",
        source_domain: "example.com"
      })

      response = conn |> get(~p"/api/browse/search?q=ragu") |> json_response(200)

      assert [%{"title" => "Sunday Sauce"}] = response["data"]
    end

    test "leaves out hand-typed recipes, which have no source domain", %{conn: conn} do
      recipe_fixture(%{title: "Grandma's Secret Lasagna", source_url: nil, source_domain: nil})

      response = conn |> get(~p"/api/browse/search?q=lasagna") |> json_response(200)

      assert response == %{"data" => [], "total" => 0}
    end

    test "leaves out archived recipes", %{conn: conn} do
      recipe = recipe_fixture(%{title: "Old Lasagna", source_domain: "example.com"})
      {:ok, _} = Controlcopypasta.Recipes.archive_recipe(recipe)

      response = conn |> get(~p"/api/browse/search?q=lasagna") |> json_response(200)

      assert response["total"] == 0
    end

    test "pages through results and reports the full total", %{conn: conn} do
      for n <- 1..3, do: recipe_fixture(%{title: "Lasagna #{n}", source_domain: "example.com"})

      response = conn |> get(~p"/api/browse/search?q=lasagna&limit=2") |> json_response(200)
      assert length(response["data"]) == 2
      assert response["total"] == 3

      response =
        conn |> get(~p"/api/browse/search?q=lasagna&limit=2&offset=2") |> json_response(200)

      assert length(response["data"]) == 1
    end

    test "returns nothing for a blank query rather than every recipe", %{conn: conn} do
      recipe_fixture(%{title: "Lasagna", source_domain: "example.com"})

      assert conn |> get(~p"/api/browse/search?q=%20") |> json_response(200) ==
               %{"data" => [], "total" => 0}

      assert conn |> get(~p"/api/browse/search") |> json_response(200) ==
               %{"data" => [], "total" => 0}
    end

    test "requires authentication" do
      conn = build_conn() |> get(~p"/api/browse/search?q=lasagna")
      assert json_response(conn, 401)
    end
  end
end
