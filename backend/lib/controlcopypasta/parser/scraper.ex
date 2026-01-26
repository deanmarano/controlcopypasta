defmodule Controlcopypasta.Parser.Scraper do
  @moduledoc """
  Behaviour for custom site-specific recipe scrapers.

  Implement this behaviour to add support for sites that don't use
  JSON-LD Schema.org markup.

  ## Example

      defmodule Controlcopypasta.Parser.Scrapers.FoodNetwork do
        @behaviour Controlcopypasta.Parser.Scraper

        @impl true
        def domains, do: ["www.foodnetwork.com", "foodnetwork.com"]

        @impl true
        def extract(html, _url) do
          # Parse HTML and extract recipe data
          {:ok, %{title: "...", ingredients: [...], ...}}
        end
      end

  Then register it in the Scraper module's @scrapers list.
  """

  @doc """
  Returns a list of domains this scraper handles.
  """
  @callback domains() :: [String.t()]

  @doc """
  Extracts recipe data from HTML.

  Returns {:ok, recipe_map} on success or {:error, reason} on failure.

  The recipe map should contain:
  - :title (required) - Recipe name
  - :description - Recipe description
  - :image_url - URL to recipe image
  - :ingredients - List of %{"text" => "...", "group" => nil | "group name"}
  - :instructions - List of %{"step" => 1, "text" => "..."}
  - :prep_time_minutes - Integer
  - :cook_time_minutes - Integer
  - :total_time_minutes - Integer
  - :servings - String like "4 servings"
  """
  @callback extract(html :: String.t(), url :: String.t()) ::
              {:ok, map()} | {:error, term()}

  # Registry of custom scrapers
  # Add new scrapers to this list
  @scrapers [
    # Controlcopypasta.Parser.Scrapers.FoodNetwork,
    # Controlcopypasta.Parser.Scrapers.HuffPost,
  ]

  @doc """
  Finds a scraper for the given URL, if one exists.
  """
  def find_scraper(url) when is_binary(url) do
    uri = URI.parse(url)
    domain = uri.host

    Enum.find(@scrapers, fn scraper ->
      domain in scraper.domains()
    end)
  end

  @doc """
  Attempts to extract recipe data using a custom scraper.
  Returns {:ok, recipe_data} or {:error, :no_scraper} if no scraper found.
  """
  def extract(html, url) do
    case find_scraper(url) do
      nil ->
        {:error, :no_scraper}

      scraper ->
        scraper.extract(html, url)
    end
  end

  @doc """
  Helper to parse HTML with Floki.
  """
  def parse_html(html) do
    Floki.parse_document(html)
  end

  @doc """
  Helper to extract text from an element.
  """
  def text(document, selector) do
    case Floki.find(document, selector) do
      [] -> nil
      elements -> elements |> Floki.text() |> String.trim() |> normalize_whitespace()
    end
  end

  @doc """
  Helper to extract all text from matching elements.
  """
  def texts(document, selector) do
    document
    |> Floki.find(selector)
    |> Enum.map(fn el -> el |> Floki.text() |> String.trim() |> normalize_whitespace() end)
    |> Enum.reject(&(&1 == ""))
  end

  @doc """
  Helper to extract an attribute value.
  """
  def attr(document, selector, attribute) do
    case Floki.find(document, selector) do
      [] -> nil
      elements -> Floki.attribute(elements, attribute) |> List.first()
    end
  end

  @doc """
  Helper to normalize ingredients into the expected format.
  """
  def normalize_ingredients(texts, group \\ nil) when is_list(texts) do
    Enum.map(texts, fn text ->
      %{"text" => normalize_whitespace(text), "group" => group}
    end)
  end

  @doc """
  Helper to normalize instructions into the expected format.
  """
  def normalize_instructions(texts) when is_list(texts) do
    texts
    |> Enum.with_index(1)
    |> Enum.map(fn {text, step} ->
      %{"step" => step, "text" => normalize_whitespace(text)}
    end)
  end

  @doc """
  Helper to parse time strings like "30 minutes", "1 hour 15 min".
  """
  def parse_time(nil), do: nil

  def parse_time(text) when is_binary(text) do
    hours =
      case Regex.run(~r/(\d+)\s*(?:hour|hr|h)/i, text) do
        [_, h] -> String.to_integer(h)
        _ -> 0
      end

    minutes =
      case Regex.run(~r/(\d+)\s*(?:minute|min|m)/i, text) do
        [_, m] -> String.to_integer(m)
        _ -> 0
      end

    case hours * 60 + minutes do
      0 -> nil
      total -> total
    end
  end

  defp normalize_whitespace(text) when is_binary(text) do
    text
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
