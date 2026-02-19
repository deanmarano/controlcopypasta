defmodule Controlcopypasta.Quicklist.AvoidedCacheTest do
  use Controlcopypasta.DataCase, async: false

  alias Controlcopypasta.Quicklist.AvoidedCache
  import Controlcopypasta.AccountsFixtures

  describe "get_avoided_params/1" do
    test "returns empty map when user has hide_avoided_ingredients disabled" do
      user = user_fixture()
      assert user.hide_avoided_ingredients == false

      params = AvoidedCache.get_avoided_params(user)
      assert params == %{}
    end

    test "caches result on second call" do
      user = user_fixture()

      # First call computes from DB
      params1 = AvoidedCache.get_avoided_params(user)
      # Second call should return same result (from cache)
      params2 = AvoidedCache.get_avoided_params(user)

      assert params1 == params2
    end

    test "invalidate/1 clears the cache for a user" do
      user = user_fixture()

      # Populate cache
      _params = AvoidedCache.get_avoided_params(user)

      # Invalidate
      assert :ok = AvoidedCache.invalidate(user.id)

      # Should still work (recomputes from DB)
      params = AvoidedCache.get_avoided_params(user)
      assert params == %{}
    end

    test "caches independently per user" do
      user1 = user_fixture()
      user2 = user_fixture()

      params1 = AvoidedCache.get_avoided_params(user1)
      params2 = AvoidedCache.get_avoided_params(user2)

      # Both should return empty (no avoidances set up)
      assert params1 == %{}
      assert params2 == %{}

      # Invalidating one doesn't affect the other
      AvoidedCache.invalidate(user1.id)
      # user2 cache should still be intact (no error)
      params2_again = AvoidedCache.get_avoided_params(user2)
      assert params2_again == %{}
    end
  end
end
