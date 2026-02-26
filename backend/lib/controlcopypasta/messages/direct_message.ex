defmodule Controlcopypasta.Messages.DirectMessage do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @valid_message_types ~w(text shared_post shared_reel forwarded)

  schema "direct_messages" do
    field :message_text, :string
    field :message_type, :string
    field :sender_username, :string
    field :platform_message_id, :string
    field :platform_timestamp, :utc_datetime_usec
    field :shared_content, :map
    field :forwarded_content, :map
    field :processed_at, :utc_datetime_usec

    belongs_to :connected_account, Controlcopypasta.Accounts.ConnectedAccount
    has_many :extracted_urls, Controlcopypasta.Messages.ExtractedUrl

    timestamps()
  end

  def changeset(direct_message, attrs) do
    direct_message
    |> cast(attrs, [
      :connected_account_id,
      :message_text,
      :message_type,
      :sender_username,
      :platform_message_id,
      :platform_timestamp,
      :shared_content,
      :forwarded_content,
      :processed_at
    ])
    |> validate_required([:connected_account_id, :message_type, :sender_username])
    |> validate_inclusion(:message_type, @valid_message_types)
    |> unique_constraint(:platform_message_id)
    |> foreign_key_constraint(:connected_account_id)
  end
end
