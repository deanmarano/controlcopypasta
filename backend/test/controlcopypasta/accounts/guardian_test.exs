defmodule Controlcopypasta.Accounts.GuardianTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Accounts.Guardian

  import Controlcopypasta.AccountsFixtures

  describe "subject_for_token/2" do
    test "returns user id as subject" do
      user = user_fixture()
      assert {:ok, subject} = Guardian.subject_for_token(user, %{})
      assert subject == user.id
    end

    test "returns error for resource without id" do
      assert {:error, :no_resource_id} = Guardian.subject_for_token(%{}, %{})
    end
  end

  describe "resource_from_claims/1" do
    test "returns user from valid claims" do
      user = user_fixture()
      claims = %{"sub" => user.id}

      assert {:ok, found_user} = Guardian.resource_from_claims(claims)
      assert found_user.id == user.id
    end

    test "returns error for non-existent user" do
      claims = %{"sub" => Ecto.UUID.generate()}
      assert {:error, :user_not_found} = Guardian.resource_from_claims(claims)
    end

    test "returns error for claims without subject" do
      assert {:error, :no_subject} = Guardian.resource_from_claims(%{})
    end
  end

  describe "encode_and_sign/1" do
    test "generates valid JWT for user" do
      user = user_fixture()

      assert {:ok, token, claims} = Guardian.encode_and_sign(user)
      assert is_binary(token)
      assert claims["sub"] == user.id
    end
  end

  describe "decode_and_verify/1" do
    test "decodes valid token" do
      user = user_fixture()
      {:ok, token, _claims} = Guardian.encode_and_sign(user)

      assert {:ok, claims} = Guardian.decode_and_verify(token)
      assert claims["sub"] == user.id
    end

    test "returns error for invalid token" do
      assert {:error, _reason} = Guardian.decode_and_verify("invalid-token")
    end
  end

  describe "refresh/1" do
    test "generates new token from existing token" do
      user = user_fixture()
      {:ok, old_token, _claims} = Guardian.encode_and_sign(user)

      assert {:ok, _old, {new_token, new_claims}} = Guardian.refresh(old_token)
      assert is_binary(new_token)
      assert new_claims["sub"] == user.id
    end
  end
end
