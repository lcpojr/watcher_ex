defmodule Authenticator.SignIn.Commands.GenerateHashTest do
  use ResourceManager.DataCase, async: true

  alias Authenticator.Crypto.Commands.GenerateHash

  describe "#{GenerateHash}.execute/2" do
    test "generates an hash using argon2" do
      assert "$argon2id$" <> _ = GenerateHash.execute("MyPassw@rd123", :argon2)
    end

    test "generates an hash using bcrypt" do
      assert "$2b$12$" <> _ = GenerateHash.execute("MyPassw@rd123", :bcrypt)
    end

    test "generates an hash using pbkdf2" do
      assert "$pbkdf2-" <> _ = GenerateHash.execute("MyPassw@rd123", :pbkdf2)
    end
  end
end
