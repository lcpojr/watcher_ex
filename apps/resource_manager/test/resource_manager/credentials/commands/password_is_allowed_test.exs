defmodule ResourceManager.Credentials.Commands.PasswordIsAllowedTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Credentials.BlocklistPasswordCache
  alias ResourceManager.Credentials.Commands.PasswordIsAllowed

  describe "#{PasswordIsAllowed}.execute/1" do
    test "returnt true if password is strong enough" do
      assert true == PasswordIsAllowed.execute("TheBiggestPasswordAll@Wed")
    end

    test "returnt false if password is not strong enough" do
      assert false == PasswordIsAllowed.execute("1234")
    end
  end

  describe "#{PasswordIsAllowed}.is_allowed?/1" do
    test "returnt true if password is allowed" do
      assert BlocklistPasswordCache.set("TheBiggestPasswordAll", "TheBiggestPasswordAll")
      assert true == PasswordIsAllowed.execute("TheBiggestPasswordAll@Wed")
    end

    test "returnt false if password is not strong enough" do
      assert BlocklistPasswordCache.set("TheBiggestPasswordAll", "TheBiggestPasswordAll")
      assert false == PasswordIsAllowed.execute("TheBiggestPasswordAll")
    end
  end
end
