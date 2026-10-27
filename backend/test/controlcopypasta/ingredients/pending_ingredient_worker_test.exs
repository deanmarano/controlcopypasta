defmodule Controlcopypasta.Ingredients.PendingIngredientWorkerTest do
  use Controlcopypasta.DataCase, async: true

  import Controlcopypasta.RecipesFixtures

  alias Controlcopypasta.Ingredients.PendingIngredient
  alias Controlcopypasta.Ingredients.PendingIngredientWorker, as: Worker
  alias Controlcopypasta.Repo

  describe "rejection_rule/1" do
    test "names the rule that rejected an ingredient" do
      assert Worker.rejection_rule("113g") == "metric_weight"
      assert Worker.rejection_rule("1/2-inch") == "inch_measurement"
      assert Worker.rejection_rule("a ") == "too_short"
      assert Worker.rejection_rule("the pan") == "blacklist_phrase"
      assert Worker.rejection_rule("cut into pieces") == "blacklist_prefix"
      assert Worker.rejection_rule("12%") == "percentage"
      assert Worker.rejection_rule("oz.") == "abbreviation"
    end

    test "returns nil for real ingredients" do
      for name <- ["nduja", "freekeh", "picanha", "xo sauce", "cooking spray"] do
        assert Worker.rejection_rule(name) == nil,
               "expected #{inspect(name)} to survive the blacklist"
      end
    end

    test "blacklisted?/1 agrees with rejection_rule/1" do
      for name <- ["113g", "nduja", "the pan", "freekeh", "12%"] do
        assert Worker.blacklisted?(name) == (Worker.rejection_rule(name) != nil)
      end
    end
  end

  describe "perform/0" do
    setup do
      recipe_fixture(%{
        ingredients: [
          # Seen once: an older version of the worker needed 5 occurrences and
          # would never have queued this.
          %{"text" => "3 tbsp nduja", "group" => nil},
          # Yields the extracted name "for the pan", which a blacklist rule
          # matches. Previously it was dropped without a trace.
          %{"text" => "butter, for the pan", "group" => nil}
        ]
      })

      :ok
    end

    test "queues an ingredient seen only once" do
      {:ok, _} = Worker.perform()

      assert %PendingIngredient{status: "pending", occurrence_count: 1} =
               Repo.get_by(PendingIngredient, name: "nduja")
    end

    test "records a blacklisted name as rejected with the rule that fired" do
      {:ok, _} = Worker.perform()

      assert %PendingIngredient{status: "rejected", rejected_by_rule: "blacklist_phrase"} =
               Repo.get_by(PendingIngredient, name: "for the pan")
    end

    test "does not overwrite a human review" do
      {:ok, _} = Worker.perform()

      Repo.get_by(PendingIngredient, name: "for the pan")
      |> PendingIngredient.changeset(%{
        status: "approved",
        reviewed_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update!()

      {:ok, _} = Worker.perform()

      assert %PendingIngredient{status: "approved"} =
               Repo.get_by(PendingIngredient, name: "for the pan")
    end
  end
end
