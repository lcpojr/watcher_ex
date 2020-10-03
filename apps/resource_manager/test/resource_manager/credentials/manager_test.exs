defmodule ResourceManager.Credentials.ManagerTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Credentials.{Cache, Manager}

  describe "Manager.execute/o" do
    test "populates the cache with the passwords" do
      assert [] == Cache.all()
      assert {:ok, :managed} = Manager.execute()
      assert [password | _] = Cache.all()
      assert is_binary(password)
    end
  end
end
