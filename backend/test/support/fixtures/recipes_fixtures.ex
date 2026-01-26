defmodule Controlcopypasta.RecipesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Controlcopypasta.Recipes` context.
  """

  def unique_recipe_title, do: "Recipe #{System.unique_integer()}"

  def valid_recipe_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      title: unique_recipe_title(),
      description: "A delicious recipe",
      source_url: "https://example.com/recipe",
      source_domain: "example.com",
      image_url: "https://example.com/image.jpg",
      ingredients: [
        %{"text" => "1 cup flour", "group" => nil},
        %{"text" => "2 eggs", "group" => nil}
      ],
      instructions: [
        %{"step" => 1, "text" => "Mix ingredients"},
        %{"step" => 2, "text" => "Bake at 350F"}
      ],
      prep_time_minutes: 15,
      cook_time_minutes: 30,
      total_time_minutes: 45,
      servings: "4 servings",
      notes: "Great for beginners"
    })
  end

  def recipe_fixture(attrs \\ %{}) do
    user = attrs[:user] || Controlcopypasta.AccountsFixtures.user_fixture()

    {:ok, recipe} =
      attrs
      |> Map.delete(:user)
      |> valid_recipe_attributes()
      |> Map.put(:user_id, user.id)
      |> Controlcopypasta.Recipes.create_recipe()

    recipe
  end

  def unique_tag_name, do: "tag-#{System.unique_integer()}"

  def valid_tag_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_tag_name()
    })
  end

  def tag_fixture(attrs \\ %{}) do
    {:ok, tag} =
      attrs
      |> valid_tag_attributes()
      |> Controlcopypasta.Recipes.create_tag()

    tag
  end
end
