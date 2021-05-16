defmodule ResourceManager.Credentials.PasswordsTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Credentials.{BlocklistPasswordCache, Passwords}
  alias ResourceManager.Credentials.Schemas.Password

  setup do
    user = insert!(:user)
    password = insert!(:password, user_id: user.id)

    {:ok, user: user, password: password}
  end

  describe "#{Passwords}.create/1" do
    test "succeed if params are valid" do
      user = insert!(:user)
      params = %{user_id: user.id, value: "MyPassw@rdTest123"}
      assert {:ok, %Password{id: id} = password} = Passwords.create(params)
      assert password.id == Repo.get(Password, id).id
    end

    test "fails if password not allowed", ctx do
      params = %{user_id: ctx.user.id, value: "123456"}
      assert BlocklistPasswordCache.set("123456", "123456")
      assert {:error, changeset} = Passwords.create(params)
      assert %{password: ["password not allowed"]} = errors_on(changeset)
    end

    test "fails if params are invalid", ctx do
      assert {:error, changeset} = Passwords.create(%{user_id: ctx.user.id})
      assert %{password_hash: ["can't be blank"]} = errors_on(changeset)
    end
  end

  describe "#{Passwords}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %Password{id: id} = password} =
               Passwords.update(ctx.password, %{value: "UpdatePassw@rdTest123"})

      assert password.id == Repo.get(Password, id).id
    end

    test "fails if params are invalid", ctx do
      assert {:error, changeset} = Passwords.update(ctx.password, %{value: 123})
      assert %{value: ["is invalid"]} = errors_on(changeset)
    end

    test "raises if password does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Passwords.update(%Password{}, %{value: "any_password"})
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
      assert {:ok, %Password{id: id}} = Passwords.delete(ctx.password)
      assert nil == Repo.get(Password, id)
    end

    test "raises if password does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Passwords.delete(%Password{})
      end
    end
  end
end
