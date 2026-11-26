defmodule Controlcopypasta.Ingredients.Detection.StatedWeight do
  @moduledoc """
  Reads a weight the recipe states in a trailing parenthetical.

      4 thin slices ham or prosciutto (about 4 oz. total)
      ½ small head of green cabbage (about 8 oz.), cored
      2 thick-cut boneless rib-eye steaks (about 1 lb. each)

  Each of those lines parses to a count -- four slices, half a head, two steaks
  -- with no weight, and a count converts to grams only for an ingredient that
  has a per-slice or per-head record. The weight is right there in the text.

  Like `RoleDetector`, this reads the ORIGINAL line, because preprocessing
  deletes the parenthetical before tokenizing: `normalize_parenthetical_notes/1`
  strips `(about <number> ...)` as a descriptive note. That stripping has to
  stay -- it is how the remainder matches the catalog -- so the weight has to be
  read before it happens.

  ## total vs each

  The two readings differ by the count, so confusing them is a 2-4x error:

      4 slices ham (about 4 oz. total)   -> 4 oz altogether
      2 rib-eye steaks (about 1 lb. each) -> 2 lb altogether

  Measured over the stored corpus, 4,417 rows say `total` and 758 say `each`.
  A bare weight with neither word behaves as `total`, which is how the corpus
  uses it: "6 medium leeks (about 1 lb.)" is a pound of leeks.
  """

  # A number as recipes write them: "4", "4.5", "1 1/2", "1½", "½".
  # The digit-plus-vulgar-fraction form is first because "1½" must not match as
  # a bare "1" with the fraction left over -- that read "about 1½ lb. total" as
  # one pound.
  @number "(?:\\d+\\s*[¼½¾⅓⅔⅛⅜⅝⅞]|\\d+\\s+\\d+/\\d+|\\d+(?:[.,]\\d+)?|\\d+/\\d+|[¼½¾⅓⅔⅛⅜⅝⅞])"

  @units %{
    "oz" => "oz",
    "oz." => "oz",
    "ounce" => "oz",
    "ounces" => "oz",
    "lb" => "lb",
    "lb." => "lb",
    "lbs" => "lb",
    "lbs." => "lb",
    "pound" => "lb",
    "pounds" => "lb",
    "g" => "g",
    "gram" => "g",
    "grams" => "g",
    "kg" => "kg",
    "kilogram" => "kg",
    "kilograms" => "kg"
  }

  @unit_pattern "oz\\.?|ounces?|lbs?\\.?|pounds?|g|grams?|kg|kilograms?"

  # A parenthetical whose weight is the only measurement: an optional "about",
  # a number or range, a weight unit, and optionally "total" or "each". Anything
  # else inside the parentheses disqualifies it, so "(about 10 oz.; if frozen,
  # thaw and drain)" and "(1 cup; 225 g)" are left alone.
  # Parenthetical contents, found with a pattern that cannot backtrack across
  # the line. Each one is then matched against @weight_only ANCHORED, so a
  # parenthetical that is not a weight fails in linear time.
  #
  # This matters: an earlier version applied the full weight pattern to the
  # whole line, and "8 ounces (1 1/2 cups; 225g) cubed pineapple" sent it into
  # catastrophic backtracking -- the alternations in @number overlap, and the
  # engine explored them exponentially before giving up.
  @parentheticals ~r/\(([^()]{0,80})\)/

  # The optional "/ <number> <unit>" tail is the metric restatement recipes add
  # for the same weight: "(about 2 lb./907 g)". It is matched so the
  # parenthetical still counts as weight-only, and then ignored -- the first
  # figure is the one taken, because that is the unit the author chose.
  @weight_only ~r/^\s*(?:about|approx\.?|approximately)?\s*(#{@number})\s*(?:[-–—]\s*(#{@number}))?\s*(#{@unit_pattern})\.?\s*(?:\/\s*#{@number}\s*(?:#{@unit_pattern})\.?\s*)?(total|each)?\s*$/iu

  @type t :: %{
          quantity: float(),
          quantity_min: float(),
          quantity_max: float(),
          unit: String.t(),
          scope: :total | :each
        }

  @doc """
  The weight stated in parentheses, or nil when the line states none.

  Returns the range as written; `:each` means the caller must multiply by the
  count, `:total` means the weight replaces it.
  """
  @spec detect(String.t()) :: t() | nil
  def detect(text) when is_binary(text) do
    @parentheticals
    |> Regex.scan(text, capture: :all_but_first)
    |> Enum.find_value(fn [inner] -> weight_only(inner) end)
  end

  def detect(_), do: nil

  defp weight_only(inner) do
    case Regex.run(@weight_only, inner, capture: :all_but_first) do
      nil ->
        nil

      captures ->
        [low, high, unit | rest] = pad(captures, 4)

        with {:ok, min} <- number(low),
             {:ok, max} <- high_number(high, min),
             {:ok, canonical} <- unit(unit) do
          %{
            quantity: (min + max) / 2,
            quantity_min: min,
            quantity_max: max,
            unit: canonical,
            scope: scope(List.first(rest))
          }
        else
          _ -> nil
        end
    end
  end

  defp pad(list, size), do: list ++ List.duplicate("", max(size - length(list), 0))

  defp scope(word) when is_binary(word) do
    if String.downcase(word) == "each", do: :each, else: :total
  end

  defp scope(_), do: :total

  defp unit(text) do
    key = text |> String.downcase() |> String.trim()

    case Map.fetch(@units, key) do
      {:ok, canonical} -> {:ok, canonical}
      :error -> Map.fetch(@units, String.trim_trailing(key, "."))
    end
  end

  defp high_number("", min), do: {:ok, min}

  defp high_number(text, min) do
    case number(text) do
      {:ok, value} when value >= min -> {:ok, value}
      # A "range" that runs backwards is not a range; treat the first figure as
      # the whole of it rather than inventing a span.
      {:ok, _} -> {:ok, min}
      other -> other
    end
  end

  @vulgar %{
    "¼" => 0.25,
    "½" => 0.5,
    "¾" => 0.75,
    "⅓" => 1 / 3,
    "⅔" => 2 / 3,
    "⅛" => 0.125,
    "⅜" => 0.375,
    "⅝" => 0.625,
    "⅞" => 0.875
  }

  defp number(text) do
    text = String.trim(text)

    cond do
      text == "" ->
        :error

      # "1½" and "1 1/2"
      match = Regex.run(~r/^(\d+)\s*([¼½¾⅓⅔⅛⅜⅝⅞])$/u, text) ->
        [_, whole, fraction] = match
        {:ok, String.to_integer(whole) + Map.fetch!(@vulgar, fraction)}

      match = Regex.run(~r/^(\d+)\s+(\d+)\/(\d+)$/, text) ->
        [_, whole, num, denom] = match
        {:ok, String.to_integer(whole) + String.to_integer(num) / String.to_integer(denom)}

      match = Regex.run(~r/^(\d+)\/(\d+)$/, text) ->
        [_, num, denom] = match
        {:ok, String.to_integer(num) / String.to_integer(denom)}

      Map.has_key?(@vulgar, text) ->
        {:ok, Map.fetch!(@vulgar, text)}

      true ->
        case Float.parse(String.replace(text, ",", ".")) do
          {value, _} -> {:ok, value}
          :error -> :error
        end
    end
  end
end
