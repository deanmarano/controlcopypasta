defmodule Controlcopypasta.Nutrition.Usda.Client do
  @moduledoc """
  Thin client for USDA FoodData Central.

  Used only by the `usda.*` mix tasks, during development, to generate seed
  data that is then committed. The running application never calls this -- it
  reads the rows the generated migration inserted. That is why the key lives in
  the dev environment rather than in production config.

  Reads `USDA_API_KEY`, which the project already defines for this API.

  `:request` can be overridden with a function of `(url, params) ->
  {:ok, map} | {:error, term}` so tests run against recorded responses rather
  than the network.
  """

  @base "https://api.nal.usda.gov/fdc/v1"

  # SR Legacy and Foundation are the reference datasets: generic whole foods
  # with full nutrient panels. Branded is excluded on purpose -- it is
  # manufacturer-submitted, partial, and tied to a specific product.
  @default_data_types ["SR Legacy", "Foundation"]

  @doc "Search for foods matching `query`. Returns the decoded `foods` list."
  @spec search(String.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def search(query, opts \\ []) do
    params = [
      query: query,
      dataType: Enum.join(Keyword.get(opts, :data_types, @default_data_types), ","),
      pageSize: Keyword.get(opts, :page_size, 10)
    ]

    case request("#{@base}/foods/search", params, opts) do
      {:ok, %{"foods" => foods}} -> {:ok, foods}
      {:ok, _other} -> {:ok, []}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc "Fetch one food's full record, including nutrients and portion weights."
  @spec food(integer() | String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def food(fdc_id, opts \\ []) do
    request("#{@base}/food/#{fdc_id}", [], opts)
  end

  defp request(url, params, opts) do
    case Keyword.get(opts, :request) do
      nil -> http_request(url, params)
      fun when is_function(fun, 2) -> fun.(url, params)
    end
  end

  defp http_request(url, params) do
    case api_key() do
      nil ->
        {:error, :missing_api_key}

      key ->
        case req_get(url, params, key) do
          {:error, %Req.TransportError{reason: {:tls_alert, _}}} ->
            # See the note on `curl_get/3`.
            curl_get(url, params, key)

          other ->
            other
        end
    end
  end

  defp req_get(url, params, key) do
    case Req.get(url,
           params: params ++ [api_key: key],
           receive_timeout: 30_000,
           connect_options: [transport_opts: transport_opts()]
         ) do
      {:ok, %Req.Response{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Fallback for one specific, diagnosed environment problem, not a general
  # escape hatch.
  #
  # api.nal.usda.gov chains through ISRG Root YR, which is cross-signed by ISRG
  # Root X1. A trust store that predates Root YR has only the cross-signed path
  # available, and OTP 27 rejects it: the cross-signed root carries CA key usage
  # (keyCertSign, cRLSign) together with extKeyUsage serverAuth, and strict path
  # validation treats that as a key_usage_mismatch. `partial_chain` cannot help,
  # because there is no already-trusted certificate in the chain to stop at.
  #
  # curl validates the same chain successfully against the same store, so this
  # shells out rather than weakening verification -- `verify_peer` stays on in
  # `req_get/3`, and nothing here passes `-k`/`--insecure`. Once the system
  # ca-certificates package ships Root YR, Req succeeds and this is never
  # reached; it can be deleted then.
  #
  # The key goes in a 0600 config file read by `--config`, never in argv, so it
  # does not show up in the process list.
  defp curl_get(url, params, key) do
    config =
      [
        ~s(url = "#{url}"),
        "get",
        "silent",
        "show-error",
        "fail"
      ] ++
        Enum.map(params ++ [api_key: key], fn {k, v} ->
          ~s(data-urlencode = "#{k}=#{v}")
        end)

    path = Path.join(System.tmp_dir!(), "fdc-#{System.unique_integer([:positive])}.conf")

    try do
      File.write!(path, Enum.join(config, "\n") <> "\n")
      File.chmod!(path, 0o600)

      case System.cmd("curl", ["--config", path], stderr_to_stdout: true) do
        {body, 0} ->
          case Jason.decode(body) do
            {:ok, decoded} when is_map(decoded) -> {:ok, decoded}
            {:ok, _} -> {:error, :unexpected_body}
            {:error, _} -> {:error, :invalid_json}
          end

        {output, status} ->
          {:error, {:curl_failed, status, String.slice(output, 0, 200)}}
      end
    after
      File.rm(path)
    end
  end

  # api.nal.usda.gov serves its chain with a cross-signed root presented as an
  # intermediate: leaf <- Let's Encrypt YR1 <- ISRG Root YR, where Root YR is
  # itself signed by ISRG Root X1. OpenSSL and curl accept that path; Erlang's
  # stricter validation rejects it with an unsupported_certificate /
  # key_usage_mismatch alert, because the cross-signed root carries CA key
  # usage while appearing mid-chain.
  #
  # `partial_chain` is the supported answer: stop validating once the chain
  # reaches a certificate already in the system trust store. Verification stays
  # on -- `verify_peer`, hostname checking and a trusted root are all still
  # required. It only permits the shorter valid path through the same roots.
  defp transport_opts do
    cacerts = :public_key.cacerts_get()

    [
      verify: :verify_peer,
      cacerts: cacerts,
      depth: 4,
      partial_chain: &partial_chain(cacerts, &1),
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]
  end

  defp partial_chain(cacerts, chain) do
    trusted = MapSet.new(cacerts, &subject/1)

    case Enum.find(chain, fn der -> MapSet.member?(trusted, subject(der)) end) do
      nil -> :unknown_ca
      der -> {:trusted_ca, der}
    end
  end

  # Matched on subject rather than on the DER bytes: a cross-signed root shares
  # its subject with the self-signed copy in the trust store but differs in
  # bytes, which is precisely why the default path fails here.
  defp subject(der) do
    der
    |> :public_key.pkix_decode_cert(:otp)
    |> elem(1)
    |> elem(6)
  rescue
    _ -> :undecodable
  end

  @doc "True when a key is configured, so a task can fail with a clear message."
  def configured?, do: not is_nil(api_key())

  defp api_key do
    case System.get_env("USDA_API_KEY") do
      nil -> nil
      "" -> nil
      key -> key
    end
  end
end
