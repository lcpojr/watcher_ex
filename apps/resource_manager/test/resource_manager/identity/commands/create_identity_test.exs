defmodule ResourceManager.Identities.Commands.CreateIdentityTest do
  use ResourceManager.DataCase, async: true

  alias ResourceManager.Identities.Commands.CreateIdentity
  alias ResourceManager.Identities.Schemas.{ClientApplication, User}
  alias ResourceManager.Ports.AuthenticatorMock
  alias ResourceManager.Repo

  setup do
    {:ok, scopes: Enum.map(insert_list!(:scope), & &1.id)}
  end

  describe "#{CreateIdentity}.execute/2" do
    test "succeeds in creating user identity if params are valid", ctx do
      input = %{
        username: "myusername",
        password_hash: gen_hashed_password(),
        scopes: ctx.scopes
      }

      assert {:ok, %User{} = user} = CreateIdentity.execute(input)
      assert user == Repo.one(User)
    end

    test "succeeds in creating client application identity if params are valid", ctx do
      input = %{
        name: "my-client-application",
        description: "App for tests",
        public_key: get_priv_public_key(),
        scopes: ctx.scopes
      }

      expect(AuthenticatorMock, :generate_hash, fn secret, :bcrypt ->
        assert is_binary(secret)
        gen_hashed_password(Ecto.UUID.generate())
      end)

      assert {:ok, %ClientApplication{} = app} = CreateIdentity.execute(input)
      assert app == Repo.one(ClientApplication)
    end

    test "fails in creating user if params are invalid" do
      assert {:error, %{errors: [password_hash: {"can't be blank", [validation: :required]}]}} =
               CreateIdentity.execute(%{username: "myusername", password_hash: nil})
    end

    test "fails in creating client application if params are invalid" do
      assert {:error, %{errors: [public_key: {"can't be blank", [validation: :required]}]}} =
               CreateIdentity.execute(%{name: "myapplication", public_key: nil})
    end
  end
end
