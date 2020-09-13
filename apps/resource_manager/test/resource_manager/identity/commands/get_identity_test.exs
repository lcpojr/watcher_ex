defmodule ResourceManager.Identity.Commands.GetIdentityTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Identity.Commands.GetIdentity
  alias ResourceManager.Identity.Commands.Inputs.{GetClientApplication, GetUser}
  alias ResourceManager.Identity.Schemas.{ClientApplication, User}
  alias ResourceManager.Repo

  setup do
    {:ok, user: insert!(:user), application: insert!(:client_application)}
  end

  describe "#{GetIdentity}.execute/2" do
    test "succeeds in getting user identity if params are valid", ctx do
      input = %{
        id: ctx.user.id,
        username: ctx.user.username,
        status: ctx.user.status
      }

      assert {:ok, %User{} = user} = GetIdentity.execute(input)
      assert user == User |> Repo.one() |> Repo.preload([:password, :scopes])
    end

    test "succeeds in getting client application identity if params are valid", ctx do
      input = %{
        id: ctx.application.id,
        client_id: ctx.application.client_id,
        name: ctx.application.name,
        status: ctx.application.status,
        protocol: ctx.application.protocol,
        access_type: ctx.application.access_type
      }

      assert {:ok, %ClientApplication{} = app} = GetIdentity.execute(input)
      assert app == ClientApplication |> Repo.one() |> Repo.preload([:public_key, :scopes])
    end

    test "fails if user does not exist" do
      assert {:error, :not_found} = GetIdentity.execute(%GetUser{id: Ecto.UUID.generate()})
    end

    test "fails if client application does not exist" do
      assert {:error, :not_found} =
               GetIdentity.execute(%GetClientApplication{id: Ecto.UUID.generate()})
    end
  end
end
