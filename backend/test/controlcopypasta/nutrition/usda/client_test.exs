defmodule Controlcopypasta.Nutrition.Usda.ClientTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Nutrition.Usda.Client

  @fixtures Path.join([__DIR__, "../../../support/fixtures/usda"])

  defp recorded(name) do
    body = @fixtures |> Path.join(name) |> File.read!() |> Jason.decode!()
    fn _url, params -> {:ok, Map.put(body, "__params", params)} end
  end

  test "search returns the foods list" do
    {:ok, foods} = Client.search("thyme fresh", request: recorded("search_thyme.json"))

    assert is_list(foods)
    assert Enum.any?(foods, &(&1["fdcId"] == 173_470))
  end

  test "search asks only for the reference datasets" do
    # Branded foods are manufacturer-submitted and partial; including them
    # would put a specific product's panel behind a generic ingredient.
    capture = fn _url, params -> {:ok, %{"foods" => [], "__params" => params}} end

    Client.search("thyme",
      request: fn url, params ->
        send(self(), {:params, params})
        capture.(url, params)
      end
    )

    assert_received {:params, params}
    assert params[:dataType] == "SR Legacy,Foundation"
  end

  test "search tolerates a response with no foods key" do
    assert {:ok, []} = Client.search("x", request: fn _, _ -> {:ok, %{}} end)
  end

  test "errors are passed through" do
    assert {:error, :boom} = Client.search("x", request: fn _, _ -> {:error, :boom} end)
  end

  test "food fetches by id" do
    {:ok, food} = Client.food(173_470, request: recorded("food_173470_thyme_fresh.json"))

    assert food["description"] == "Thyme, fresh"
  end
end
