defmodule Controlcopypasta.AccountsTest do
  use Controlcopypasta.DataCase, async: true

  alias Controlcopypasta.Accounts
  alias Controlcopypasta.Accounts.User

  import Controlcopypasta.AccountsFixtures

  describe "get_user/1" do
    test "returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user(user.id) == user
    end

    test "returns nil if user does not exist" do
      assert Accounts.get_user(Ecto.UUID.generate()) == nil
    end
  end

  describe "get_user!/1" do
    test "returns the user with given id" do
      user = user_fixture()
      assert Accounts.get_user!(user.id) == user
    end

    test "raises if user does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(Ecto.UUID.generate())
      end
    end
  end

  describe "get_user_by_email/1" do
    test "returns user with matching email" do
      user = user_fixture()
      assert Accounts.get_user_by_email(user.email) == user
    end

    test "returns user regardless of email case" do
      user = user_fixture(%{email: "test@example.com"})
      assert Accounts.get_user_by_email("TEST@example.com") == user
      assert Accounts.get_user_by_email("Test@Example.COM") == user
    end

    test "returns nil if no user found" do
      assert Accounts.get_user_by_email("nonexistent@example.com") == nil
    end
  end

  describe "create_user/1" do
    test "creates user with valid email" do
      assert {:ok, %User{} = user} = Accounts.create_user(%{email: "test@example.com"})
      assert user.email == "test@example.com"
    end

    test "downcases email on create" do
      assert {:ok, %User{} = user} = Accounts.create_user(%{email: "TEST@EXAMPLE.COM"})
      assert user.email == "test@example.com"
    end

    test "returns error for invalid email format" do
      assert {:error, changeset} = Accounts.create_user(%{email: "invalid"})
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "returns error for email with spaces" do
      assert {:error, changeset} = Accounts.create_user(%{email: "test @example.com"})
      assert "must have the @ sign and no spaces" in errors_on(changeset).email
    end

    test "returns error for missing email" do
      assert {:error, changeset} = Accounts.create_user(%{})
      assert "can't be blank" in errors_on(changeset).email
    end

    test "returns error for duplicate email" do
      user_fixture(%{email: "dupe@example.com"})
      assert {:error, changeset} = Accounts.create_user(%{email: "dupe@example.com"})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "returns error for email longer than 255 characters" do
      long_email = String.duplicate("a", 250) <> "@b.com"
      assert {:error, changeset} = Accounts.create_user(%{email: long_email})
      assert "should be at most 255 character(s)" in errors_on(changeset).email
    end
  end

  describe "get_or_create_user/1" do
    test "returns existing user if email exists" do
      existing_user = user_fixture(%{email: "existing@example.com"})
      assert {:ok, user} = Accounts.get_or_create_user("existing@example.com")
      assert user.id == existing_user.id
    end

    test "creates new user if email doesn't exist" do
      assert {:ok, user} = Accounts.get_or_create_user("new@example.com")
      assert user.email == "new@example.com"
    end

    test "handles case-insensitive email matching" do
      existing_user = user_fixture(%{email: "case@example.com"})
      assert {:ok, user} = Accounts.get_or_create_user("CASE@EXAMPLE.COM")
      assert user.id == existing_user.id
    end
  end
end
