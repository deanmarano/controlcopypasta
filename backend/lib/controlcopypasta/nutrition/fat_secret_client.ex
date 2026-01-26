defmodule Controlcopypasta.Nutrition.FatSecretClient do
  @moduledoc """
  Client for FatSecret Platform API.

  FatSecret provides comprehensive nutrition data including branded products,
  restaurant foods, and generic ingredients. Good for US branded products.

  ## Setup

  1. Register at: https://platform.fatsecret.com/
  2. Create an application to get credentials
  3. Add to your environment:
     - `FATSECRET_CLIENT_ID` - OAuth 2.0 Client ID
     - `FATSECRET_CLIENT_SECRET` - OAuth 2.0 Client Secret

  ## API Documentation
  https://platform.fatsecret.com/api/

  ## Rate Limits
  - Free tier: 5,000 API calls per month
  - Requests should be spaced to avoid rate limiting
  """

  require Logger

  @api_base "https://platform.fatsecret.com/rest"
  @token_url "https://oauth.fatsecret.com/connect/token"

  # Cache the access token in process dictionary (simple approach)
  # In production, consider using ETS or a GenServer for shared caching

  @doc """
  Search for foods by name.

  Returns a list of matching foods with basic nutrition info.

  ## Options
  - `:page` - Page number (default 0)
  - `:max_results` - Results per page (default 20, max 50)
  - `:region` - Region code for localized results (default "US")

  ## Examples

      iex> search("cheerios")
      {:ok, [%{food_id: "33181", food_name: "Cheerios", brand_name: "General Mills", ...}, ...]}
  """
  def search(query, opts \\ []) do
    page = opts[:page] || 0
    max_results = opts[:max_results] || 20

    # Use foods.search (basic scope) instead of foods.search.v3 (premier scope)
    params = %{
      method: "foods.search",
      search_expression: query,
      page_number: page,
      max_results: max_results,
      format: "json"
    }

    case api_request(params) do
      {:ok, %{"foods" => %{"food" => foods}}} when is_list(foods) ->
        {:ok, Enum.map(foods, &parse_search_result/1)}

      {:ok, %{"foods" => %{"food" => food}}} when is_map(food) ->
        # Single result comes as a map, not a list
        {:ok, [parse_search_result(food)]}

      {:ok, %{"foods" => %{"total_results" => "0"}}} ->
        {:ok, []}

      {:ok, %{"foods" => nil}} ->
        {:ok, []}

      {:ok, response} ->
        Logger.warning("Unexpected FatSecret search response: #{inspect(response)}")
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get detailed nutrition data for a specific food by ID.

  ## Examples

      iex> get_food("33181")
      {:ok, %{
        food_id: "33181",
        food_name: "Cheerios",
        brand_name: "General Mills",
        nutrients: %{calories: 100, protein_g: 3, ...}
      }}
  """
  def get_food(food_id, _opts \\ []) do
    params = %{
      method: "food.get.v4",
      food_id: food_id,
      format: "json"
    }

    case api_request(params) do
      {:ok, %{"food" => food}} ->
        {:ok, parse_food_detail(food)}

      {:ok, %{"error" => error}} ->
        Logger.warning("FatSecret error: #{inspect(error)}")
        {:error, :not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Search and get the best matching food's nutrition data.

  Prioritizes branded products when available.
  """
  def search_and_get_nutrition(query, opts \\ []) do
    case search(query, opts) do
      {:ok, []} ->
        {:error, :not_found}

      {:ok, results} ->
        # Prefer branded products, then by relevance
        best =
          results
          |> Enum.sort_by(fn r -> if r.brand_name, do: 0, else: 1 end)
          |> List.first()

        get_food(best.food_id, opts)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Search specifically for branded foods.
  """
  def search_branded(query, opts \\ []) do
    case search(query, opts) do
      {:ok, results} ->
        branded = Enum.filter(results, & &1.brand_name)
        {:ok, branded}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Parse search result into a simpler structure
  defp parse_search_result(food) do
    %{
      food_id: food["food_id"],
      food_name: food["food_name"],
      brand_name: food["brand_name"],
      food_type: food["food_type"],
      food_url: food["food_url"]
    }
  end

  # Parse full food detail with nutrients
  defp parse_food_detail(food) do
    # FatSecret returns servings as a list or single object
    servings = get_servings(food)

    # Find the "per 100g" serving if available, otherwise use first serving
    serving =
      Enum.find(servings, List.first(servings), fn s ->
        s["metric_serving_amount"] == "100" and s["metric_serving_unit"] == "g"
      end)

    nutrients = parse_nutrients(serving)

    # Determine serving size info
    {serving_value, serving_unit, serving_desc} = parse_serving_info(serving)

    %{
      food_id: food["food_id"],
      food_name: food["food_name"],
      brand_name: food["brand_name"],
      food_type: food["food_type"],
      food_url: food["food_url"],
      serving_size_value: serving_value,
      serving_size_unit: serving_unit,
      serving_description: serving_desc,
      nutrients: nutrients
    }
  end

  defp get_servings(food) do
    case food["servings"]["serving"] do
      servings when is_list(servings) -> servings
      serving when is_map(serving) -> [serving]
      _ -> []
    end
  end

  defp parse_serving_info(nil), do: {100, "g", nil}

  defp parse_serving_info(serving) do
    # Prefer metric serving if available
    value =
      case serving["metric_serving_amount"] do
        nil -> parse_number(serving["number_of_units"]) || 100
        amount -> parse_number(amount) || 100
      end

    unit =
      case serving["metric_serving_unit"] do
        nil -> "serving"
        u -> u
      end

    desc = serving["serving_description"]

    {value, unit, desc}
  end

  defp parse_nutrients(nil), do: %{}

  defp parse_nutrients(serving) do
    %{
      calories: parse_number(serving["calories"]),
      protein_g: parse_number(serving["protein"]),
      fat_total_g: parse_number(serving["fat"]),
      fat_saturated_g: parse_number(serving["saturated_fat"]),
      fat_trans_g: parse_number(serving["trans_fat"]),
      fat_polyunsaturated_g: parse_number(serving["polyunsaturated_fat"]),
      fat_monounsaturated_g: parse_number(serving["monounsaturated_fat"]),
      carbohydrates_g: parse_number(serving["carbohydrate"]),
      fiber_g: parse_number(serving["fiber"]),
      sugar_g: parse_number(serving["sugar"]),
      sodium_mg: parse_number(serving["sodium"]),
      potassium_mg: parse_number(serving["potassium"]),
      calcium_mg: parse_number(serving["calcium"]),
      iron_mg: parse_number(serving["iron"]),
      cholesterol_mg: parse_number(serving["cholesterol"]),
      vitamin_a_mcg: parse_vitamin_a(serving),
      vitamin_c_mg: parse_vitamin_c(serving),
      vitamin_d_mcg: parse_number(serving["vitamin_d"])
    }
  end

  # FatSecret returns vitamin A as percentage of daily value (900 mcg = 100%)
  defp parse_vitamin_a(serving) do
    case parse_number(serving["vitamin_a"]) do
      nil -> nil
      percent -> percent * 9  # 900 mcg * percent / 100
    end
  end

  # FatSecret returns vitamin C as percentage of daily value (90 mg = 100%)
  defp parse_vitamin_c(serving) do
    case parse_number(serving["vitamin_c"]) do
      nil -> nil
      percent -> percent * 0.9  # 90 mg * percent / 100
    end
  end

  defp parse_number(nil), do: nil
  defp parse_number(val) when is_number(val), do: val

  defp parse_number(val) when is_binary(val) do
    case Float.parse(val) do
      {num, _} -> num
      :error -> nil
    end
  end

  # OAuth 2.0 Client Credentials flow
  defp get_access_token do
    # Check if we have a cached token that's still valid
    case Process.get(:fatsecret_token) do
      {token, expires_at} when is_binary(token) ->
        if DateTime.compare(DateTime.utc_now(), expires_at) == :lt do
          {:ok, token}
        else
          fetch_new_token()
        end

      _ ->
        fetch_new_token()
    end
  end

  defp fetch_new_token do
    client_id = get_client_id()
    client_secret = get_client_secret()

    if is_nil(client_id) or is_nil(client_secret) do
      {:error, :missing_credentials}
    else
      body = URI.encode_query(%{
        grant_type: "client_credentials",
        scope: "basic"
      })

      auth = Base.encode64("#{client_id}:#{client_secret}")

      headers = [
        {"content-type", "application/x-www-form-urlencoded"},
        {"authorization", "Basic #{auth}"}
      ]

      case Req.post(@token_url, body: body, headers: headers) do
        {:ok, %{status: 200, body: %{"access_token" => token, "expires_in" => expires_in}}} ->
          expires_at = DateTime.add(DateTime.utc_now(), expires_in - 60, :second)
          Process.put(:fatsecret_token, {token, expires_at})
          {:ok, token}

        {:ok, %{status: status, body: body}} ->
          Logger.error("FatSecret token error: #{status} - #{inspect(body)}")
          {:error, {:auth_error, status}}

        {:error, reason} ->
          Logger.error("FatSecret token request failed: #{inspect(reason)}")
          {:error, reason}
      end
    end
  end

  defp api_request(params) do
    case get_access_token() do
      {:ok, token} ->
        url = "#{@api_base}/server.api"
        query = URI.encode_query(params)

        headers = [
          {"authorization", "Bearer #{token}"},
          {"content-type", "application/x-www-form-urlencoded"}
        ]

        case Req.post(url, body: query, headers: headers) do
          {:ok, %{status: 200, body: body}} ->
            {:ok, body}

          {:ok, %{status: 429}} ->
            Logger.warning("FatSecret API rate limit hit")
            {:error, :rate_limited}

          {:ok, %{status: status, body: body}} ->
            Logger.error("FatSecret API error: #{status} - #{inspect(body)}")
            {:error, {:api_error, status}}

          {:error, reason} ->
            Logger.error("FatSecret API request failed: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_client_id do
    System.get_env("FATSECRET_CLIENT_ID") ||
      System.get_env("FATSECRET_CLIENT_ID_OAUTH2") ||
      Application.get_env(:controlcopypasta, :fatsecret_client_id)
  end

  defp get_client_secret do
    System.get_env("FATSECRET_CLIENT_SECRET") ||
      System.get_env("FATSECRET_CLIENT_SECRET_OAUTH2") ||
      Application.get_env(:controlcopypasta, :fatsecret_client_secret)
  end

  @doc """
  Checks if API credentials are configured.
  """
  def credentials_configured? do
    get_client_id() != nil and get_client_secret() != nil
  end
end
