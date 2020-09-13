defmodule Authenticator.Sessions.AccessTokensTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.Sessions.AccessTokens
  alias Authenticator.Sessions.Schemas.AccessToken

  setup do
    {:ok, access_token: insert!(:access_token)}
  end

  describe "#{AccessTokens}.create/1" do
    test "succeed if params are valid" do
      params = %{
        jti: Ecto.UUID.generate(),
        claims: %{},
        status: "active",
        grant_flow: "resource_owner",
        expires_at: default_expiration()
      }

      assert {:ok, %AccessToken{id: id} = access_token} = AccessTokens.create(params)
      assert access_token == Repo.get(AccessToken, id)
    end

    test "fails if params are invalid" do
      assert {:error,
              %{
                errors: [
                  jti: {"can't be blank", _},
                  claims: {"can't be blank", _},
                  expires_at: {"can't be blank", _},
                  grant_flow: {"can't be blank", _}
                ]
              }} = AccessTokens.create(%{})
    end
  end

  describe "#{AccessTokens}.update/2" do
    test "succeed if params are valid", ctx do
      assert {:ok, %AccessToken{id: id, status: "expired"} = access_token} =
               AccessTokens.update(ctx.access_token, %{status: "expired"})

      assert access_token == Repo.get(AccessToken, id)
    end

    test "fails if params are invalid", ctx do
      assert {:error, %{errors: [status: {"is invalid", _}]}} =
               AccessTokens.update(ctx.access_token, %{status: 123})
    end

    test "raises if access_token does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        AccessTokens.update(%AccessToken{}, %{status: "expired"})
      end
    end
  end

  describe "#{AccessTokens}.get_by/1" do
    test "succeed if params are valid", ctx do
      assert %AccessToken{} = AccessTokens.get_by(id: ctx.access_token.id)
    end

    test "returns nil if nothing was found" do
      assert nil == AccessTokens.get_by(id: Ecto.UUID.generate())
    end
  end

  describe "#{AccessTokens}.list/1" do
    test "succeed if params are valid", ctx do
      assert [%AccessToken{}] = AccessTokens.list(id: ctx.access_token.id)
    end

    test "returns empty list if nothing was found" do
      assert [] == AccessTokens.list(id: Ecto.UUID.generate())
    end
  end

  describe "#{AccessTokens}.delete/1" do
    test "succeed if params are valid", ctx do
      assert {:ok, %AccessToken{id: id}} = AccessTokens.delete(ctx.access_token)
      assert nil == Repo.get(AccessToken, id)
    end

    test "raises if access_token does not exist" do
      assert_raise Ecto.NoPrimaryKeyValueError, fn ->
        AccessTokens.delete(%AccessToken{})
      end
    end
  end
end
