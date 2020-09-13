defmodule Authenticator.SignIn.Commands.FakeVerifyHashTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.Crypto.Commands.FakeVerifyHash

  describe "#{FakeVerifyHash}.execute/1" do
    test "runs argon2 and returns false", ctx do
      assert false == FakeVerifyHash.execute(:argon2)
    end

    test "runs bcrypt and returns false", ctx do
      assert false == FakeVerifyHash.execute(:bcrypt)
    end

    test "runs pbkdf2 and returns false", ctx do
      assert false == FakeVerifyHash.execute(:pbkdf2)
    end
  end
end
