defmodule Controlcopypasta.Ingredients.NotePhraseBoundaryTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Ingredients.Tokenizer

  defp names(text) do
    text |> Tokenizer.tokenize() |> Enum.map(& &1.text)
  end

  describe "note phrases are matched at word boundaries" do
    test "'to thin' is not found inside 'into thin'" do
      tokens = names("1 lb beef round steak, cut into thin strips")
      refute Enum.any?(tokens, &String.contains?(&1, "__NOTE_"))
      assert "into" in tokens
    end

    test "'or less' is not found inside 'for less'" do
      tokens = names("1 serrano chile pepper, seeded for less heat")
      refute Enum.any?(tokens, &String.contains?(&1, "__NOTE_"))
    end

    test "'or more' is not found inside 'for more'" do
      tokens = names("2 tbsp sugar, or for more sweetness")
      refute Enum.any?(tokens, &String.contains?(&1, "__NOTE_"))
    end

    test "a standalone note phrase is still marked as a note" do
      tokens = Tokenizer.tokenize("1 tbsp water to thin")
      assert Enum.any?(tokens, fn t -> t.label == :note and t.text == "to thin" end)
    end

    test "'to taste' is still marked as a note" do
      tokens = Tokenizer.tokenize("salt to taste")
      assert Enum.any?(tokens, fn t -> t.label == :note and t.text == "to taste" end)
    end
  end
end
