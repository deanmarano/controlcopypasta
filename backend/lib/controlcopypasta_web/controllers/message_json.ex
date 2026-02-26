defmodule ControlcopypastaWeb.MessageJSON do
  alias Controlcopypasta.Messages.{DirectMessage, ExtractedUrl}

  def index(%{messages: messages}) do
    %{data: for(message <- messages, do: data(message))}
  end

  def show(%{message: message}) do
    %{data: data(message)}
  end

  defp data(%DirectMessage{} = message) do
    %{
      id: message.id,
      message_text: message.message_text,
      message_type: message.message_type,
      sender_username: message.sender_username,
      platform_message_id: message.platform_message_id,
      platform_timestamp: message.platform_timestamp,
      shared_content: message.shared_content,
      forwarded_content: message.forwarded_content,
      processed_at: message.processed_at,
      inserted_at: message.inserted_at,
      extracted_urls: extracted_urls(message.extracted_urls)
    }
  end

  defp extracted_urls(urls) when is_list(urls) do
    Enum.map(urls, &extracted_url_data/1)
  end

  defp extracted_urls(_), do: []

  defp extracted_url_data(%ExtractedUrl{} = eu) do
    %{
      id: eu.id,
      url: eu.url,
      source: eu.source,
      parse_status: eu.parse_status,
      parse_error: eu.parse_error,
      recipe_title: get_in(eu.parsed_recipe_data, ["title"]),
      recipe_id: eu.recipe_id,
      inserted_at: eu.inserted_at
    }
  end
end
