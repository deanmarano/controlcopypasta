defmodule Controlcopypasta.Parser.BrowserFetch do
  @moduledoc """
  Fetches HTML using a pooled headless browser (Playwright) for sites that block
  regular HTTP requests with bot detection.

  Uses a pool of persistent browser workers for efficient resource usage.
  """

  alias Controlcopypasta.Browser.Pool

  # Domains known to require browser fetching
  @browser_required_domains [
    "www.foodnetwork.com",
    "foodnetwork.com"
  ]

  @doc """
  Returns true if this URL is known to require browser fetching.
  """
  def browser_required?(url) when is_binary(url) do
    uri = URI.parse(url)
    uri.host in @browser_required_domains
  end

  @doc """
  Fetches HTML from a URL using a pooled headless browser.
  Returns {:ok, html} or {:error, reason}.
  """
  def fetch(url) when is_binary(url) do
    Pool.fetch_html(url)
  end
end
