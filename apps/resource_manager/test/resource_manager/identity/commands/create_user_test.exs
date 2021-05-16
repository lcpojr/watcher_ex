defmodule ResourceManager.Identities.Commands.CreateUserTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Identities.Commands.CreateUser
  alias ResourceManager.Identities.Schemas.User
  alias ResourceManager.Repo

  setup do
    {:ok, scopes: Enum.map(insert_list!(:scope), & &1.id)}
  end

  describe "#{CreateUser}.execute/2" do
    test "succeeds in creating user identity if params are valid", ctx do
      input = %{
        username: "myusername",
        password: %{value: "my_secure_password"},
        permission: %{scopes: ctx.scopes}
      }

      assert {:ok, %User{} = user} = CreateUser.execute(input)
      assert user.id == Repo.one(User).id
    end

    test "fails in creating user if params are invalid" do
      assert {:error, changeset} = CreateUser.execute(%{})
      assert %{username: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
