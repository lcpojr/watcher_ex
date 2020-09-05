defmodule ResourceManager.Commands.CreateIdentityTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Commands.CreateIdentity
  alias ResourceManager.Commands.Inputs.{CreateClientApplication, CreateUser}
  alias ResourceManager.Identity.Schemas.{ClientApplication, User}
  alias ResourceManager.Repo

  setup do
    {:ok, scopes: Enum.map(insert_list!(:scope), & &1.id)}
  end

  describe "#{CreateIdentity}.execute/2" do
    test "succeeds in creating user identity if params are valid", ctx do
      input = %CreateUser{
        username: "myusername",
        password: "My-passw@rd",
        scopes: ctx.scopes
      }

      assert {:ok, %User{} = user} = CreateIdentity.execute(input)
      assert user == Repo.one(User)
    end

    test "succeeds in creating client application identity if params are valid", ctx do
      input = %CreateClientApplication{
        name: "my-client-application",
        description: "App for tests",
        public_key: get_priv_public_key(),
        scopes: ctx.scopes
      }

      assert {:ok, %ClientApplication{} = app} = CreateIdentity.execute(input)
      assert app == Repo.one(ClientApplication)
    end
  end
end
