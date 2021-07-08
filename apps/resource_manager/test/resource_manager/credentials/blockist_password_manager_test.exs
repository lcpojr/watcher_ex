defmodule ResourceManager.Credentials.BlocklistPasswordManagerTest do
  @moduledoc false

  use ResourceManager.DataCase, async: true

  alias ResourceManager.Credentials.{BlocklistPasswordCache, BlocklistPasswordManager}

  describe "#{BlocklistPasswordManager}.execute/0" do
    test "populates the cache with the passwords" do
      assert [] == BlocklistPasswordCache.all()
      assert {:ok, :managed} = BlocklistPasswordManager.execute()
      assert [password | _] = BlocklistPasswordCache.all()
      assert is_binary(password)
    end
  end
end
