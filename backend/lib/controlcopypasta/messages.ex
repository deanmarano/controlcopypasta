defmodule Controlcopypasta.Messages do
  @moduledoc """
  The Messages context for managing direct messages from social platforms.
  """

  import Ecto.Query, warn: false
  alias Controlcopypasta.Repo
  alias Controlcopypasta.Messages.{DirectMessage, ExtractedUrl}
  alias Controlcopypasta.Accounts.ConnectedAccount
  alias Controlcopypasta.Recipes

  @url_regex ~r/https?:\/\/[^\s<>"{}|\\^\[\]]+/i

  @doc """
  Creates a direct message, extracts URLs, and spawns background parsing.
  """
  def create_message(attrs) do
    changeset = DirectMessage.changeset(%DirectMessage{}, attrs)

    Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, message} ->
          urls = extract_urls_from_message(message)

          extracted =
            Enum.map(urls, fn {url, source} ->
              {:ok, eu} =
                %ExtractedUrl{}
                |> ExtractedUrl.changeset(%{
                  direct_message_id: message.id,
                  url: url,
                  source: source
                })
                |> Repo.insert()

              eu
            end)

          message = %{message | extracted_urls: extracted}

          if Enum.any?(extracted) do
            Task.Supervisor.start_child(Controlcopypasta.TaskSupervisor, fn ->
              process_extracted_urls(message.id)
            end)
          end

          message

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  @doc """
  Lists direct messages for a user, ordered by platform_timestamp desc.
  Queries through connected_accounts to verify ownership.
  """
  def list_messages_for_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    DirectMessage
    |> join(:inner, [dm], ca in ConnectedAccount, on: dm.connected_account_id == ca.id)
    |> where([_dm, ca], ca.user_id == ^user_id)
    |> order_by([dm], desc: coalesce(dm.platform_timestamp, dm.inserted_at))
    |> limit(^limit)
    |> offset(^offset)
    |> preload(:extracted_urls)
    |> Repo.all()
  end

  @doc """
  Gets a single message for a user, verified through connected_account ownership.
  """
  def get_message_for_user(user_id, message_id) do
    DirectMessage
    |> join(:inner, [dm], ca in ConnectedAccount, on: dm.connected_account_id == ca.id)
    |> where([dm, ca], dm.id == ^message_id and ca.user_id == ^user_id)
    |> preload(:extracted_urls)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      message -> {:ok, message}
    end
  end

  @doc """
  Saves a recipe from a successfully parsed extracted URL.
  Creates the recipe and links it on the extracted_url record.
  """
  def save_recipe_from_url(user_id, extracted_url_id) do
    with {:ok, eu} <- get_extracted_url_for_user(user_id, extracted_url_id),
         :ok <- validate_saveable(eu),
         {:ok, recipe} <- create_recipe_from_parsed_data(user_id, eu.parsed_recipe_data) do
      eu
      |> ExtractedUrl.changeset(%{recipe_id: recipe.id})
      |> Repo.update()

      {:ok, recipe}
    end
  end

  @doc """
  Finds a connected account by provider and provider_username.
  """
  def find_connected_account(provider, provider_username) do
    ConnectedAccount
    |> where([ca], ca.provider == ^provider and ca.provider_username == ^provider_username)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  @doc """
  Checks if a message with the given platform_message_id already exists.
  """
  def message_exists?(platform_message_id) when is_binary(platform_message_id) do
    DirectMessage
    |> where([dm], dm.platform_message_id == ^platform_message_id)
    |> Repo.exists?()
  end

  def message_exists?(_), do: false

  # Private helpers

  defp extract_urls_from_message(%DirectMessage{} = message) do
    text_urls =
      if message.message_text do
        @url_regex
        |> Regex.scan(message.message_text)
        |> Enum.map(fn [url] -> {url, "message_text"} end)
      else
        []
      end

    shared_url =
      case message.shared_content do
        %{"url" => url} when is_binary(url) and url != "" -> [{url, "shared_content"}]
        _ -> []
      end

    forwarded_url =
      case message.forwarded_content do
        %{"original_url" => url} when is_binary(url) and url != "" ->
          [{url, "forwarded_content"}]

        _ ->
          []
      end

    (text_urls ++ shared_url ++ forwarded_url)
    |> Enum.uniq_by(fn {url, _source} -> url end)
  end

  defp process_extracted_urls(message_id) do
    extracted_urls =
      ExtractedUrl
      |> where([eu], eu.direct_message_id == ^message_id and eu.parse_status == "pending")
      |> Repo.all()

    Enum.each(extracted_urls, fn eu ->
      task = Task.async(fn -> Controlcopypasta.Parser.parse_url(eu.url) end)

      case Task.yield(task, 10_000) || Task.shutdown(task) do
        {:ok, {:ok, recipe_data}} ->
          eu
          |> ExtractedUrl.changeset(%{
            parse_status: "success",
            parsed_recipe_data: stringify_keys(recipe_data)
          })
          |> Repo.update()

        {:ok, {:error, reason}} ->
          eu
          |> ExtractedUrl.changeset(%{
            parse_status: "failed",
            parse_error: to_string(reason)
          })
          |> Repo.update()

        nil ->
          eu
          |> ExtractedUrl.changeset(%{
            parse_status: "failed",
            parse_error: "Parsing timed out"
          })
          |> Repo.update()
      end
    end)

    # Mark the message as processed
    DirectMessage
    |> where([dm], dm.id == ^message_id)
    |> Repo.update_all(set: [processed_at: DateTime.utc_now()])
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn
      {k, v} when is_atom(k) -> {Atom.to_string(k), stringify_keys(v)}
      {k, v} -> {k, stringify_keys(v)}
    end)
  end

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(value), do: value

  defp get_extracted_url_for_user(user_id, extracted_url_id) do
    ExtractedUrl
    |> join(:inner, [eu], dm in DirectMessage, on: eu.direct_message_id == dm.id)
    |> join(:inner, [_eu, dm], ca in ConnectedAccount, on: dm.connected_account_id == ca.id)
    |> where([eu, _dm, ca], eu.id == ^extracted_url_id and ca.user_id == ^user_id)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      eu -> {:ok, eu}
    end
  end

  defp validate_saveable(%ExtractedUrl{parse_status: "success", recipe_id: nil}), do: :ok

  defp validate_saveable(%ExtractedUrl{recipe_id: id}) when not is_nil(id),
    do: {:error, :already_saved}

  defp validate_saveable(_), do: {:error, :not_parsed}

  defp create_recipe_from_parsed_data(user_id, parsed_data) when is_map(parsed_data) do
    recipe_attrs =
      parsed_data
      |> Map.put("user_id", user_id)
      |> Map.take([
        "user_id",
        "title",
        "description",
        "source_url",
        "source_domain",
        "image_url",
        "ingredients",
        "instructions",
        "prep_time_minutes",
        "cook_time_minutes",
        "total_time_minutes",
        "servings",
        "yield"
      ])

    Recipes.create_recipe(recipe_attrs)
  end
end
