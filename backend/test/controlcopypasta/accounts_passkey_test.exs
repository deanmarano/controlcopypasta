defmodule Controlcopypasta.AccountsPasskeyTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Accounts.Passkey

  import Controlcopypasta.AccountsFixtures

  def passkey_fixture(user, attrs \\ %{}) do
    default_attrs = %{
      credential_id: :crypto.strong_rand_bytes(32),
      public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7}),
      sign_count: 0,
      name: "Test Passkey",
      transports: ["internal"]
    }

    {:ok, passkey} = Accounts.create_passkey(user, Map.merge(default_attrs, attrs))
    passkey
  end

  describe "list_passkeys/1" do
    test "returns all passkeys for a user" do
      user = user_fixture()
      passkey1 = passkey_fixture(user, %{name: "Passkey 1"})
      passkey2 = passkey_fixture(user, %{name: "Passkey 2"})

      passkeys = Accounts.list_passkeys(user.id)

      assert length(passkeys) == 2
      assert Enum.any?(passkeys, fn p -> p.id == passkey1.id end)
      assert Enum.any?(passkeys, fn p -> p.id == passkey2.id end)
    end

    test "returns empty list when user has no passkeys" do
      user = user_fixture()
      assert Accounts.list_passkeys(user.id) == []
    end

    test "does not return passkeys from other users" do
      user1 = user_fixture()
      user2 = user_fixture()
      passkey_fixture(user1)

      assert Accounts.list_passkeys(user2.id) == []
    end

    test "returns passkeys ordered by inserted_at" do
      user = user_fixture()
      passkey1 = passkey_fixture(user, %{name: "First"})
      passkey2 = passkey_fixture(user, %{name: "Second"})

      passkeys = Accounts.list_passkeys(user.id)

      assert hd(passkeys).id == passkey1.id
      assert List.last(passkeys).id == passkey2.id
    end
  end

  describe "get_passkey/2" do
    test "returns the passkey for the user" do
      user = user_fixture()
      passkey = passkey_fixture(user)

      result = Accounts.get_passkey(user.id, passkey.id)

      assert result.id == passkey.id
    end

    test "returns nil if passkey doesn't exist" do
      user = user_fixture()
      assert Accounts.get_passkey(user.id, Ecto.UUID.generate()) == nil
    end

    test "returns nil if passkey belongs to another user" do
      user1 = user_fixture()
      user2 = user_fixture()
      passkey = passkey_fixture(user1)

      assert Accounts.get_passkey(user2.id, passkey.id) == nil
    end
  end

  describe "get_passkey_by_credential_id/1" do
    test "returns passkey with preloaded user" do
      user = user_fixture()
      credential_id = :crypto.strong_rand_bytes(32)
      passkey = passkey_fixture(user, %{credential_id: credential_id})

      result = Accounts.get_passkey_by_credential_id(credential_id)

      assert result.id == passkey.id
      assert result.user.id == user.id
      assert result.user.email == user.email
    end

    test "returns nil for unknown credential_id" do
      assert Accounts.get_passkey_by_credential_id(:crypto.strong_rand_bytes(32)) == nil
    end
  end

  describe "create_passkey/2" do
    test "creates passkey with valid attributes" do
      user = user_fixture()

      attrs = %{
        credential_id: :crypto.strong_rand_bytes(32),
        public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7}),
        sign_count: 0,
        name: "My Passkey",
        transports: ["internal", "hybrid"]
      }

      assert {:ok, %Passkey{} = passkey} = Accounts.create_passkey(user, attrs)
      assert passkey.user_id == user.id
      assert passkey.name == "My Passkey"
      assert passkey.transports == ["internal", "hybrid"]
    end

    test "returns error for duplicate credential_id" do
      user = user_fixture()
      credential_id = :crypto.strong_rand_bytes(32)
      passkey_fixture(user, %{credential_id: credential_id})

      attrs = %{
        credential_id: credential_id,
        public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7})
      }

      assert {:error, changeset} = Accounts.create_passkey(user, attrs)
      assert "has already been taken" in errors_on(changeset).credential_id
    end
  end

  describe "update_passkey_sign_count/2" do
    test "updates the sign count" do
      user = user_fixture()
      passkey = passkey_fixture(user, %{sign_count: 5})

      assert {:ok, updated} = Accounts.update_passkey_sign_count(passkey, 10)
      assert updated.sign_count == 10
    end
  end

  describe "delete_passkey/1" do
    test "deletes the passkey" do
      user = user_fixture()
      passkey = passkey_fixture(user)

      assert {:ok, _} = Accounts.delete_passkey(passkey)
      assert Accounts.get_passkey(user.id, passkey.id) == nil
    end
  end

  describe "count_passkeys/1" do
    test "returns the count of passkeys for a user" do
      user = user_fixture()
      passkey_fixture(user)
      passkey_fixture(user)

      assert Accounts.count_passkeys(user.id) == 2
    end

    test "returns 0 when user has no passkeys" do
      user = user_fixture()
      assert Accounts.count_passkeys(user.id) == 0
    end
  end
end
