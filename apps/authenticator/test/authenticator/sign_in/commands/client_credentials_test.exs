defmodule Authenticator.SignIn.Commands.ClientCredentialsTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.Ports.ResourceManagerMock
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.Commands.ClientCredentials, as: Command

  describe "#{Command}.execute/1" do
    test "succeeds and generates an access_token" do
      scopes = RF.insert_list!(:scope, 3)
      app = RF.insert!(:client_application, grant_flows: ["client_credentials"])

      subject_id = app.id
      client_id = app.client_id
      client_name = app.name
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        grant_type: "client_credentials",
        scope: scope,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | scopes: scopes}}
      end)

      assert {:ok,
              %{
                access_token: access_token,
                refresh_token: nil,
                expires_in: 7200,
                token_type: typ
              }} = Command.execute(input)

      assert {:ok,
              %{
                "aud" => ^client_id,
                "azp" => ^client_name,
                "exp" => _,
                "iat" => _,
                "iss" => "WatcherEx",
                "jti" => jti,
                "nbf" => _,
                "scope" => ^scope,
                "identity" => "user",
                "sub" => ^subject_id,
                "typ" => ^typ
              }} = AccessToken.verify_and_validate(access_token)

      assert %Session{jti: ^jti} = Repo.one(Session)
    end

    test "succeeds and generates a refresh_token" do
      scopes = RF.insert_list!(:scope, 3)
      app = RF.insert!(:client_application, grant_flows: ["client_credentials", "refresh_token"])

      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        grant_type: "client_credentials",
        scope: scope,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | scopes: scopes}}
      end)

      assert {:ok,
              %{
                access_token: access_token,
                refresh_token: refresh_token,
                expires_in: 7200,
                token_type: typ
              }} = Command.execute(input)

      assert {:ok, %{"jti" => jti}} = RefreshToken.verify_and_validate(access_token)

      assert {:ok,
              %{
                "aud" => ^client_id,
                "ati" => ^jti,
                "exp" => _,
                "iat" => _,
                "iss" => "WatcherEx",
                "jti" => _,
                "nbf" => _,
                "typ" => ^typ
              }} = RefreshToken.verify_and_validate(refresh_token)

      assert %Session{jti: ^jti} = Repo.one(Session)
    end

    test "fails if params are invalid" do
      assert {:error,
              %Ecto.Changeset{
                errors: [
                  client_id: {"can't be blank", [validation: :required]},
                  client_secret: {"can't be blank", [validation: :required]},
                  scope: {"can't be blank", [validation: :required]}
                ]
              }} = Command.execute(%{grant_type: "client_credentials"})
    end

    test "fails if client application do not exist" do
      input = %{
        grant_type: "client_credentials",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ -> {:error, :not_found} end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application flow is not enabled" do
      input = %{
        grant_type: "client_credentials",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, grant_flows: [])}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application is inactive" do
      app =
        RF.insert!(
          :client_application,
          grant_flows: ["client_credentials"],
          status: "blocked"
        )

      input = %{
        grant_type: "client_credentials",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, app}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application secret do not match credential" do
      input = %{
        grant_type: "client_credentials",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: Ecto.UUID.generate()
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, secret: "another-secret")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application protocol is not openid-connect" do
      input = %{
        grant_type: "client_credentials",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, protocol: "saml")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end
  end
end
