defmodule ControlcopypastaWeb.BotMessageController do
  use ControlcopypastaWeb, :controller

  alias Controlcopypasta.Messages

  def create(conn, %{"provider" => provider, "provider_username" => provider_username, "message" => message_params}) do
    # Check for duplicate
    platform_message_id = message_params["platform_message_id"]

    if platform_message_id && Messages.message_exists?(platform_message_id) do
      conn
      |> put_status(:ok)
      |> json(%{status: "duplicate", message: "Message already received"})
    else
      with {:ok, account} <- Messages.find_connected_account(provider, provider_username),
           attrs <- build_message_attrs(account.id, message_params),
           {:ok, message} <- Messages.create_message(attrs) do
        conn
        |> put_status(:accepted)
        |> json(%{
          status: "accepted",
          message_id: message.id,
          urls_found: length(message.extracted_urls)
        })
      else
        {:error, :not_found} ->
          conn
          |> put_status(:not_found)
          |> json(%{error: "Connected account not found"})

        {:error, %Ecto.Changeset{} = changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> put_view(json: ControlcopypastaWeb.ChangesetJSON)
          |> render(:error, changeset: changeset)
      end
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required fields: provider, provider_username, message"})
  end

  defp build_message_attrs(connected_account_id, params) do
    %{
      connected_account_id: connected_account_id,
      message_text: params["text"],
      message_type: params["type"] || "text",
      sender_username: params["sender_username"],
      platform_message_id: params["platform_message_id"],
      platform_timestamp: parse_timestamp(params["timestamp"]),
      shared_content: params["shared_content"],
      forwarded_content: params["forwarded_content"]
    }
  end

  defp parse_timestamp(nil), do: nil

  defp parse_timestamp(timestamp) when is_binary(timestamp) do
    case DateTime.from_iso8601(timestamp) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp parse_timestamp(_), do: nil
end
