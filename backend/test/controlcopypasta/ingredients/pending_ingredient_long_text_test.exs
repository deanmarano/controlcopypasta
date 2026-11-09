defmodule Controlcopypasta.Ingredients.PendingIngredientLongTextTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Ingredients.PendingIngredient
  alias Controlcopypasta.Repo

  # 15 production recipe lines exceed 255 characters (longest: 590). One of
  # them aborted a full pending scan 16 chunks into 89 with
  # ERROR 22001 (string_data_right_truncation).
  @long_line String.duplicate("a very long ingredient line ", 25)

  test "a sample text longer than 255 characters can be stored" do
    assert String.length(@long_line) > 255

    assert {:ok, saved} =
             %PendingIngredient{}
             |> PendingIngredient.changeset(%{
               name: "long sample holder",
               occurrence_count: 1,
               sample_texts: [@long_line]
             })
             |> Repo.insert()

    assert Repo.get!(PendingIngredient, saved.id).sample_texts == [@long_line]
  end

  test "an existing row can be updated with a long sample text" do
    {:ok, row} =
      %PendingIngredient{}
      |> PendingIngredient.changeset(%{name: "update target", sample_texts: ["short"]})
      |> Repo.insert()

    assert {:ok, updated} =
             row
             |> PendingIngredient.changeset(%{sample_texts: [@long_line, "short"]})
             |> Repo.update()

    assert @long_line in updated.sample_texts
  end

  test "a name longer than 255 characters can be stored" do
    long_name = String.duplicate("x", 300)

    assert {:ok, _} =
             %PendingIngredient{}
             |> PendingIngredient.changeset(%{name: long_name})
             |> Repo.insert()
  end
end
