defmodule ResourceManager.Identities.Commands.CreateClientApplicationTest do
  @moduledoc false

  use ResourceManager.DataCase, async: true

  alias ResourceManager.Identities.Commands.CreateClientApplication
  alias ResourceManager.Identities.Schemas.ClientApplication
  alias ResourceManager.Repo

  setup do
    {:ok, scopes: Enum.map(insert_list!(:scope), & &1.id)}
  end

  describe "#{CreateClientApplication}.execute/2" do
    test "succeeds in creating user identity if params are valid", ctx do
      input = %{
        name: "my-client-application",
        description: "App for tests",
        public_key: get_public_key(),
        scopes: ctx.scopes
      }

      assert {:ok, %ClientApplication{} = user} = CreateClientApplication.execute(input)
      assert user.id == Repo.one(ClientApplication).id
    end

    test "fails in creating user if params are invalid" do
      assert {:error, changeset} = CreateClientApplication.execute(%{})
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end
  end
end
