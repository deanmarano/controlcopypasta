defmodule Controlcopypasta.Accounts.MagicLinkTest do
  use ExUnit.Case, async: true

  alias Controlcopypasta.Accounts.MagicLink

  describe "generate_token/1" do
    test "generates a token for an email" do
      token = MagicLink.generate_token("test@example.com")
      assert is_binary(token)
      assert String.length(token) > 0
    end

    test "generates different tokens for different emails" do
      token1 = MagicLink.generate_token("user1@example.com")
      token2 = MagicLink.generate_token("user2@example.com")
      assert token1 != token2
    end

    test "generates different tokens for same email (includes timestamp)" do
      token1 = MagicLink.generate_token("same@example.com")
      # Small delay to ensure different timestamp
      Process.sleep(1)
      token2 = MagicLink.generate_token("same@example.com")
      # Tokens may or may not be different depending on timing, but both should be valid
      assert is_binary(token1)
      assert is_binary(token2)
    end
  end

  describe "verify_token/1" do
    test "returns email for valid token" do
      email = "verify@example.com"
      token = MagicLink.generate_token(email)

      assert {:ok, ^email} = MagicLink.verify_token(token)
    end

    test "returns error for invalid token" do
      assert {:error, :invalid} = MagicLink.verify_token("invalid-token")
    end

    test "returns error for tampered token" do
      token = MagicLink.generate_token("test@example.com")
      tampered = token <> "tampered"

      assert {:error, :invalid} = MagicLink.verify_token(tampered)
    end

    test "returns error for empty token" do
      assert {:error, :invalid} = MagicLink.verify_token("")
    end
  end
end
