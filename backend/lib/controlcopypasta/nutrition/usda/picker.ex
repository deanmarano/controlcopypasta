defmodule Controlcopypasta.Nutrition.Usda.Picker do
  @moduledoc """
  Decides whether a set of FoodData Central candidates identifies one food
  clearly enough to use without a human looking at it.

  This is the safety gate of the import. A search for "thyme" returns both
  `Thyme, fresh` (101 kcal/100g) and `Spices, thyme, dried` (276), and picking
  by search rank would write one of those into several thousand recipe rows.
  So anything ambiguous is held back for review rather than resolved by a
  heuristic.
  """

  # Each group is mutually exclusive, and crossing one changes the figure per
  # gram several times over.
  @opposing_groups [
    ~w(fresh dried),
    ~w(raw cooked boiled roasted),
    ~w(sweetened unsweetened),
    ~w(salted unsalted),
    ~w(canned frozen)
  ]

  @type candidate :: %{
          required(:description) => String.t() | nil,
          required(:calories_per_100g) => number() | nil,
          optional(:exact_name_match) => boolean(),
          optional(any()) => any()
        }

  @doc """
  Returns `{confident?, reason}` for a ranked candidate list.

  The list must be in the order the API returned, because the first entry is
  the one that would be used.
  """
  @spec assess(String.t(), [candidate()]) :: {boolean(), String.t()}
  def assess(_name, []), do: {false, "no candidates"}

  def assess(name, [only]), do: assess(name, [only], [])

  def assess(name, [first | rest]), do: assess(name, [first], rest)

  defp assess(name, [first], rest) do
    cond do
      is_nil(first.calories_per_100g) ->
        {false, "top candidate has no calorie value"}

      missing = missing_words(name, first.description) ->
        # The check that matters most. FoodData Central's search is fuzzy, and
        # its top hit routinely names a different food: "xanthan gum" returns
        # "Chewing gum", "shaoxing wine" returns "Vinegar, red wine", "aleppo
        # pepper" returns "Pepper, banana, raw". Each of those ranked first and
        # each is wrong, so rank is not evidence of identity -- the description
        # has to actually contain what we asked for.
        {false, "top candidate does not mention #{missing} -- pick one by hand"}

      extra = unexpected_words(name, first.description) ->
        # The description names our ingredient and then something else:
        # "cabbage" returns "Cabbage, kimchi" ahead of "Cabbage, raw".
        {false, "top candidate adds \"#{extra}\" -- pick one by hand"}

      conflict = first_conflict(first, rest) ->
        {false, "candidates differ in kind (#{conflict}) -- pick one by hand"}

      true ->
        {true, "description matches: #{first.description}"}
    end
  end

  # Words of the canonical name absent from the description, or nil when all
  # are present. Compared on a crude singular stem so "sugar" matches "Sugars".
  defp missing_words(name, description) do
    described = MapSet.new(words(description), &stem/1)

    case Enum.reject(significant(name), &MapSet.member?(described, stem(&1))) do
      [] -> nil
      missing -> Enum.join(missing, ", ")
    end
  end

  # Words the description adds that change which food it is. FDC prefixes a
  # category ("Cheese, cheddar", "Spices, thyme") and appends preparation
  # qualifiers; those are benign. Anything else is a different food.
  #
  # Kept deliberately short. An earlier version also treated "oil", "nut",
  # "seed", "leaf" and "powder" as benign, on the theory that they were
  # category prefixes too. They are not -- they name a different food made from
  # the same plant, and the gate accepted "walnut" -> "Oil, walnut" (884
  # kcal/100g against the nut's 654) as unambiguous. Both failures are tests.
  # Words that do not change which food it is: FDC's category prefixes, and
  # qualifiers that describe the plain, unmodified form.
  @benign_extras ~w(raw unprepared nfs ns includes commercially prepared
                    whole cheese cheeses spice spices)

  # Everything else -- "dried", "ground", "cooked", "canned", "oil", "juice" --
  # is left out on purpose, so it has to appear in our own name before a pick
  # counts as unambiguous. "sage" returned "Spices, sage, ground": dried and
  # ground, while the stored lines ask for sage by the leaf and the bunch,
  # which is the fresh herb at roughly a third the calories per gram.

  defp unexpected_words(name, description) do
    wanted = MapSet.new(significant(name), &stem/1)
    benign = MapSet.new(@benign_extras, &stem/1)

    extras =
      description
      |> words()
      |> Enum.reject(fn word ->
        MapSet.member?(wanted, stem(word)) or MapSet.member?(benign, stem(word))
      end)

    case extras do
      [] -> nil
      [first | _] -> first
    end
  end

  @stopwords ~w(and or of with in a an the for)

  defp significant(name) do
    name |> words() |> Enum.reject(&(&1 in @stopwords))
  end

  defp stem(word), do: String.trim_trailing(word, "s")

  @doc """
  Describes the first mutually exclusive disagreement between the top candidate
  and any other, or nil when they agree about what the food is.
  """
  @spec first_conflict(candidate(), [candidate()]) :: String.t() | nil
  def first_conflict(first, rest) do
    first_words = words(first.description)

    Enum.find_value(rest, fn other ->
      other_words = words(other.description)

      Enum.find_value(@opposing_groups, fn group ->
        mine = Enum.filter(group, &(&1 in first_words))
        theirs = Enum.filter(group, &(&1 in other_words))

        if mine != [] and theirs != [] and mine != theirs do
          "#{hd(mine)} vs #{hd(theirs)}"
        end
      end)
    end)
  end

  defp words(nil), do: []

  defp words(description),
    do: description |> String.downcase() |> String.split(~r/[^a-z]+/, trim: true)
end
