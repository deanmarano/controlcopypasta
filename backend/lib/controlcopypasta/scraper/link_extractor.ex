defmodule Controlcopypasta.Scraper.LinkExtractor do
  @moduledoc """
  Extracts recipe links from HTML pages.

  Uses heuristics to identify links that are likely recipe pages:
  - Links containing "recipe" in the path
  - Links matching common recipe URL patterns
  - Links from recipe index/listing pages
  """

  @doc """
  Extracts potential recipe links from HTML.

  Returns a list of absolute URLs that are likely recipe pages.
  """
  def extract_recipe_links(html, base_url) do
    base_uri = URI.parse(base_url)

    html
    |> Floki.parse_document!()
    |> Floki.find("a[href]")
    |> Enum.flat_map(fn {"a", attrs, _children} ->
      case List.keyfind(attrs, "href", 0) do
        {"href", href} -> [href]
        _ -> []
      end
    end)
    |> Enum.map(&resolve_url(&1, base_uri))
    |> Enum.filter(&valid_recipe_url?/1)
    |> Enum.uniq()
  end

  @doc """
  Extracts all links from HTML (for general crawling).

  Returns a list of absolute URLs.
  """
  def extract_all_links(html, base_url) do
    base_uri = URI.parse(base_url)

    html
    |> Floki.parse_document!()
    |> Floki.find("a[href]")
    |> Enum.flat_map(fn {"a", attrs, _children} ->
      case List.keyfind(attrs, "href", 0) do
        {"href", href} -> [href]
        _ -> []
      end
    end)
    |> Enum.map(&resolve_url(&1, base_uri))
    |> Enum.filter(&valid_url?/1)
    |> Enum.uniq()
  end

  # Resolves relative URLs to absolute URLs
  defp resolve_url(href, base_uri) do
    href = String.trim(href)

    cond do
      # Already absolute URL
      String.starts_with?(href, "http://") or String.starts_with?(href, "https://") ->
        href

      # Protocol-relative URL
      String.starts_with?(href, "//") ->
        "#{base_uri.scheme || "https"}:#{href}"

      # Root-relative URL
      String.starts_with?(href, "/") ->
        "#{base_uri.scheme}://#{base_uri.host}#{href}"

      # Fragment or empty
      String.starts_with?(href, "#") or href == "" ->
        nil

      # JavaScript or other non-HTTP protocols
      String.contains?(href, ":") and not String.starts_with?(href, "http") ->
        nil

      # Relative URL
      true ->
        base_path = base_uri.path || "/"
        dir_path = Path.dirname(base_path)
        "#{base_uri.scheme}://#{base_uri.host}#{Path.join(dir_path, href)}"
    end
  end

  # Checks if URL matches recipe URL patterns
  defp valid_recipe_url?(nil), do: false

  defp valid_recipe_url?(url) when is_binary(url) do
    uri = URI.parse(url)

    cond do
      # Must have a path
      is_nil(uri.path) ->
        false

      # Skip non-HTTP URLs
      uri.scheme not in ["http", "https"] ->
        false

      # Skip common non-recipe paths
      skip_path?(uri.path) ->
        false

      # Must match recipe patterns
      true ->
        recipe_path?(uri.path)
    end
  end

  defp valid_url?(nil), do: false

  defp valid_url?(url) when is_binary(url) do
    uri = URI.parse(url)
    uri.scheme in ["http", "https"] and not is_nil(uri.host)
  end

  # Patterns that indicate recipe pages
  @recipe_patterns [
    ~r"/recipe[s]?/",
    ~r"/rezept[e]?/",
    ~r"-recipe$",
    ~r"-recipe/",
    ~r"/cooking/",
    ~r"/dishes?/"
  ]

  defp recipe_path?(path) do
    path_lower = String.downcase(path)

    Enum.any?(@recipe_patterns, fn pattern ->
      Regex.match?(pattern, path_lower)
    end)
  end

  # Paths to skip (non-recipe content)
  @skip_patterns [
    ~r"^/tag[s]?/",
    ~r"^/categor",
    ~r"^/author[s]?/",
    ~r"^/about",
    ~r"^/contact",
    ~r"^/privacy",
    ~r"^/terms",
    ~r"^/search",
    ~r"^/login",
    ~r"^/register",
    ~r"^/account",
    ~r"^/cart",
    ~r"^/shop",
    ~r"^/store",
    ~r"^/subscribe",
    ~r"^/newsletter",
    ~r"\.pdf$",
    ~r"\.jpg$",
    ~r"\.png$",
    ~r"\.gif$",
    ~r"\.css$",
    ~r"\.js$"
  ]

  defp skip_path?(path) do
    path_lower = String.downcase(path)

    Enum.any?(@skip_patterns, fn pattern ->
      Regex.match?(pattern, path_lower)
    end)
  end
end
