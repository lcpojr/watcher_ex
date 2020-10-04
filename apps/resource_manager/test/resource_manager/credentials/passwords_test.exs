defmodule ResourceManager.Credentials.PasswordsTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Credentials.{Cache, Passwords}
  alias ResourceManager.Credentials.Schemas.Password

  setup do
    user = insert!(:user)
    password = insert!(:password, user_id: user.id)

    {:ok, user: user, password: password}
  end

  describe "#{Passwords}.create/1" do
    test "succeed if params are valid" do
      user = insert!(:user)
      params = %{user_id: user.id, password_hash: gen_hashed_password("MyPassw@rdTest123")}

      assert {:ok, %Password{id: id} = password} = Passwords.create(params)
      assert password == Repo.get(Password, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, %{errors: [password_hash: {"can't be blank", _}]}} =
               Passwords.create(%{user_id: ctx.user.id})
    end
  end

  describe "#{Passwords}.update/2" do
    test "succeed if params are valid", ctx do
      password_hash = gen_hashed_password("UpdatePassw@rdTest123")

      assert {:ok, %Password{id: id, password_hash: ^password_hash} = password} =
               Passwords.update(ctx.password, %{password_hash: password_hash})

      assert password == Repo.get(Password, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, %{errors: [password_hash: {"is invalid", _}]}} =
               Passwords.update(ctx.password, %{password_hash: 123})
    end

    test "raises if password does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Passwords.update(%Password{}, %{password_hash: gen_hashed_password()})
      end
    end
  end

  describe "#{Passwords}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %Password{} = Passwords.get_by(id: ctx.password.id)
    end

    test "returns nil if nothing was found" do
      assert nil == Passwords.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{Passwords}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%Password{}] = Passwords.list(id: ctx.password.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == Passwords.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{Passwords}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %Password{id: id} = password} = Passwords.delete(ctx.password)
      assert nil == Repo.get(Password, id)
    end

    test "raises if password does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Passwords.delete(%Password{})
      end
    end
  end

  describe "#{Passwords}.is_strong?/1" do
    test "returnt true if password is strong enough" do
      assert true == Passwords.is_strong?("TheBiggestPasswordAll@Wed")
    end

    test "returnt false if password is not strong enough" do
      assert false == Passwords.is_strong?("1234")
    end
  end

  describe "#{Passwords}.is_allowed?/1" do
    test "returnt true if password is allowed" do
      assert Cache.set("TheBiggestPasswordAll", "TheBiggestPasswordAll")
      assert true == Passwords.is_strong?("TheBiggestPasswordAll@Wed")
    end

    test "returnt false if password is not strong enough" do
      assert Cache.set("TheBiggestPasswordAll", "TheBiggestPasswordAll")
      assert false == Passwords.is_strong?("TheBiggestPasswordAll")
    end
  end
end
