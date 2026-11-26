defmodule ControlcopypastaWeb.InboxControllerTest do
  use ControlcopypastaWeb.ConnCase, async: true

  import Controlcopypasta.AccountsFixtures

  alias Controlcopypasta.Repo
  alias Controlcopypasta.Messages
  alias Controlcopypasta.Accounts.ConnectedAccount
  alias Controlcopypasta.Messages.{DirectMessage, ExtractedUrl}

  setup :setup_authenticated_conn

  defp message_fixture(user, url_attrs \\ %{}) do
    account =
      %ConnectedAccount{}
      |> ConnectedAccount.changeset(%{
        user_id: user.id,
        provider: "instagram",
        provider_username: "cook#{System.unique_integer([:positive])}"
      })
      |> Repo.insert!()

    message =
      %DirectMessage{}
      |> DirectMessage.changeset(%{
        connected_account_id: account.id,
        message_type: "shared_post",
        sender_username: "a_friend"
      })
      |> Repo.insert!()

    url =
      %ExtractedUrl{}
      |> ExtractedUrl.changeset(
        Map.merge(
          %{
            direct_message_id: message.id,
            url: "https://example.com/recipe",
            source: "shared_content",
            parse_status: "failed",
            parse_error: "Parsing timed out"
          },
          url_attrs
        )
      )
      |> Repo.insert!()

    %{message: message, url: url}
  end

  describe "DELETE /api/inbox/:id" do
    test "removes the message and its URLs", %{conn: conn, user: user} do
      %{message: message, url: url} = message_fixture(user)

      conn = delete(conn, ~p"/api/inbox/#{message.id}")

      assert response(conn, 204)
      assert Repo.get(DirectMessage, message.id) == nil
      assert Repo.get(ExtractedUrl, url.id) == nil
    end

    test "cannot remove someone else's message", %{conn: conn} do
      %{message: message} = message_fixture(user_fixture())

      conn = delete(conn, ~p"/api/inbox/#{message.id}")

      assert json_response(conn, 404)
      assert Repo.get(DirectMessage, message.id)
    end
  end

  describe "POST /api/inbox/:message_id/urls/:url_id/retry" do
    test "refuses a URL that already parsed", %{conn: conn, user: user} do
      %{message: message, url: url} = message_fixture(user, %{parse_status: "success"})

      conn = post(conn, ~p"/api/inbox/#{message.id}/urls/#{url.id}/retry")

      assert json_response(conn, 409)
      assert Repo.get(ExtractedUrl, url.id).parse_status == "success"
    end

    test "cannot retry someone else's URL", %{conn: conn} do
      %{message: message, url: url} = message_fixture(user_fixture())

      conn = post(conn, ~p"/api/inbox/#{message.id}/urls/#{url.id}/retry")

      assert json_response(conn, 404)
      assert Repo.get(ExtractedUrl, url.id).parse_status == "failed"
    end
  end

  # The retry endpoint itself starts a background fetch of the URL, so the
  # state change is tested here without it.
  describe "Messages.reset_extracted_url_for_retry/2" do
    test "puts a failed URL back to pending and clears the error", %{user: user} do
      %{url: url} = message_fixture(user)

      assert {:ok, reset} = Messages.reset_extracted_url_for_retry(user.id, url.id)

      assert reset.parse_status == "pending"
      assert reset.parse_error == nil
    end

    test "accepts a URL stuck in pending", %{user: user} do
      %{url: url} = message_fixture(user, %{parse_status: "pending", parse_error: nil})

      assert {:ok, %ExtractedUrl{parse_status: "pending"}} =
               Messages.reset_extracted_url_for_retry(user.id, url.id)
    end

    test "leaves a parsed URL alone", %{user: user} do
      %{url: url} = message_fixture(user, %{parse_status: "success"})

      assert {:error, :already_parsed} = Messages.reset_extracted_url_for_retry(user.id, url.id)
    end

    test "does not find another user's URL", %{user: user} do
      %{url: url} = message_fixture(user_fixture())

      assert {:error, :not_found} = Messages.reset_extracted_url_for_retry(user.id, url.id)
    end
  end
end
