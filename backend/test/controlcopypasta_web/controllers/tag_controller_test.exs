defmodule ControlcopypastaWeb.TagControllerTest do
  use ControlcopypastaWeb.ConnCase, async: true

  import Controlcopypasta.RecipesFixtures

  setup :setup_authenticated_conn

  describe "GET /api/tags (index)" do
    test "lists all tags", %{conn: conn} do
      _tag1 = tag_fixture(%{name: "breakfast"})
      _tag2 = tag_fixture(%{name: "dinner"})

      conn = get(conn, ~p"/api/tags")
      response = json_response(conn, 200)

      assert length(response["data"]) == 2
      names = Enum.map(response["data"], & &1["name"])
      assert "breakfast" in names
      assert "dinner" in names
    end

    test "returns empty list when no tags exist", %{conn: conn} do
      conn = get(conn, ~p"/api/tags")
      assert json_response(conn, 200)["data"] == []
    end

    test "returns 401 without authentication" do
      conn = build_conn() |> get(~p"/api/tags")
      assert json_response(conn, 401)
    end
  end

  describe "POST /api/tags (create)" do
    test "creates tag with valid name", %{conn: conn} do
      attrs = %{tag: %{name: "new-tag"}}

      conn = post(conn, ~p"/api/tags", attrs)
      response = json_response(conn, 201)

      assert response["data"]["name"] == "new-tag"
      assert response["data"]["id"]
    end

    test "returns errors for missing name", %{conn: conn} do
      attrs = %{tag: %{name: nil}}

      conn = post(conn, ~p"/api/tags", attrs)
      assert json_response(conn, 422)["errors"]["name"]
    end

    test "returns errors for duplicate name", %{conn: conn} do
      tag_fixture(%{name: "existing"})
      attrs = %{tag: %{name: "existing"}}

      conn = post(conn, ~p"/api/tags", attrs)
      assert json_response(conn, 422)["errors"]["name"]
    end

    test "returns errors for name too long", %{conn: conn} do
      attrs = %{tag: %{name: String.duplicate("a", 101)}}

      conn = post(conn, ~p"/api/tags", attrs)
      assert json_response(conn, 422)["errors"]["name"]
    end
  end

  describe "DELETE /api/tags/:id" do
    test "deletes existing tag", %{conn: conn} do
      tag = tag_fixture()

      conn = delete(conn, ~p"/api/tags/#{tag.id}")
      assert response(conn, 204)

      assert Controlcopypasta.Recipes.get_tag(tag.id) == nil
    end

    test "returns 404 for non-existent tag", %{conn: conn} do
      conn = delete(conn, ~p"/api/tags/#{Ecto.UUID.generate()}")
      assert json_response(conn, 404)
    end
  end
end
