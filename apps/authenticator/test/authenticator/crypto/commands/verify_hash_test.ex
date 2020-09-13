defmodule Authenticator.SignIn.Commands.VerifyHashTest do
  use ResourceManager.DataCase, async: true

  alias Authenticator.Crypto.Commands.VerifyHash

  describe "#{VerifyHash}.execute/2" do
    setup do
      {:ok, password: "MyPassw@rd123"}
    end

    test "verifies an hash using argon2 and returns true if valid", ctx do
      hash = Argon2.hash_pwd_salt(ctx.password)
      assert true == VerifyHash.execute(ctx.password, hash, :argon2)
    end

    test "verifies an hash using bcrypt and returns true if valid", ctx do
      hash = Bcrypt.hash_pwd_salt(ctx.password)
      assert true == VerifyHash.execute(ctx.password, hash, :bcrypt)
    end

    test "verifies an hash using pbkdf2 and returns true if valid", ctx do
      hash = Pbkdf2.hash_pwd_salt(ctx.password)
      assert true == VerifyHash.execute(ctx.password, hash, :pbkdf2)
    end

    test "runs argon2 verification by the given input", ctx do
      hash = Argon2.hash_pwd_salt(ctx.password)

      assert true ==
               VerifyHash.execute(
                 %{password: %{password_hash: hash, algorithm: "argon2"}},
                 ctx.password
               )
    end

    test "runs bcrypt verification by the given input", ctx do
      hash = Bcrypt.hash_pwd_salt(ctx.password)

      assert true ==
               VerifyHash.execute(
                 %{password: %{password_hash: hash, algorithm: "bcrypt"}},
                 ctx.password
               )
    end

    test "runs pbkdf2 verification by the given input", ctx do
      hash = Pbkdf2.hash_pwd_salt(ctx.password)

      assert true ==
               VerifyHash.execute(
                 %{password: %{password_hash: hash, algorithm: "pbkdf2"}},
                 ctx.password
               )
    end

    test "returns false if hash do not match in argon2", ctx do
      hash = Argon2.hash_pwd_salt("my-hash")
      assert false == VerifyHash.execute(ctx.password, hash, :argon2)
    end

    test "returns false if hash do not match in bcrypt", ctx do
      hash = Bcrypt.hash_pwd_salt("my-hash")
      assert false == VerifyHash.execute(ctx.password, hash, :bcrypt)
    end

    test "returns false if hash do not match in pbkdf2", ctx do
      hash = Pbkdf2.hash_pwd_salt("my-hash")
      assert false == VerifyHash.execute(ctx.password, hash, :pbkdf2)
    end
  end
end
