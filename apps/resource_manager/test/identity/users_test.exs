defmodule ResourceManager.Identity.UsersTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Identity.Schemas.User
  alias ResourceManager.Identity.Users

  setup do
    {:ok, user: insert!(:user)}
  end

  describe "#{Users}.create/1" do
    test "succeed if params are valid" do
      params = %{username: "myusername@gmail.com"}
      assert {:ok, %User{id: id} = user} = Users.create(params)
      assert user == Repo.get(User, id)
    end

    test "fails if params are invalid" do
      assert {:error, %{errors: [username: {"can't be blank", _}]}} = Users.create(%{})
    end
  end

  describe "#{Users}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %User{username: "updated_username@gmail.com", id: id} = user} =
               Users.update(ctx.user, %{username: "updated_username@gmail.com"})

      assert user == Repo.get(User, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, %{errors: [username: {"is invalid", _}]}} =
               Users.update(ctx.user, %{username: 123})
    end

    test "raises if user does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Users.update(%User{}, %{username: "newusername"})
      end
    end
  end

  describe "#{Users}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %User{} = Users.get_by(id: ctx.user.id)
    end

    test "returns nil if nothing was found" do
      assert nil == Users.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{Users}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%User{}] = Users.list(id: ctx.user.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == Users.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{Users}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %User{id: id} = user} = Users.delete(ctx.user)
      assert nil == Repo.get(User, id)
    end

    test "raises if user does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        Users.delete(%User{})
      end
    end
  end
end
