defmodule Controlcopypasta.Accounts.PasskeyTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Accounts.Passkey

  import Controlcopypasta.AccountsFixtures

  describe "changeset/2" do
    test "valid changeset with required fields" do
      user = user_fixture()

      attrs = %{
        credential_id: :crypto.strong_rand_bytes(32),
        public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7}),
        user_id: user.id
      }

      changeset = Passkey.changeset(%Passkey{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset with all fields" do
      user = user_fixture()

      attrs = %{
        credential_id: :crypto.strong_rand_bytes(32),
        public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7}),
        user_id: user.id,
        sign_count: 5,
        name: "My MacBook",
        aaguid: :crypto.strong_rand_bytes(16),
        transports: ["internal", "hybrid"]
      }

      changeset = Passkey.changeset(%Passkey{}, attrs)
      assert changeset.valid?
    end

    test "invalid without credential_id" do
      user = user_fixture()

      attrs = %{
        public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7}),
        user_id: user.id
      }

      changeset = Passkey.changeset(%Passkey{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).credential_id
    end

    test "invalid without public_key" do
      user = user_fixture()

      attrs = %{
        credential_id: :crypto.strong_rand_bytes(32),
        user_id: user.id
      }

      changeset = Passkey.changeset(%Passkey{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).public_key
    end

    test "invalid without user_id" do
      attrs = %{
        credential_id: :crypto.strong_rand_bytes(32),
        public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7})
      }

      changeset = Passkey.changeset(%Passkey{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "default values are set" do
      user = user_fixture()

      attrs = %{
        credential_id: :crypto.strong_rand_bytes(32),
        public_key: :erlang.term_to_binary(%{1 => 2, 3 => -7}),
        user_id: user.id
      }

      changeset = Passkey.changeset(%Passkey{}, attrs)
      assert Ecto.Changeset.get_field(changeset, :sign_count) == 0
      assert Ecto.Changeset.get_field(changeset, :name) == "Passkey"
    end
  end

  describe "update_sign_count_changeset/2" do
    test "updates sign_count" do
      passkey = %Passkey{sign_count: 5}
      changeset = Passkey.update_sign_count_changeset(passkey, 10)

      assert changeset.valid?
      assert Ecto.Changeset.get_change(changeset, :sign_count) == 10
    end
  end
end
