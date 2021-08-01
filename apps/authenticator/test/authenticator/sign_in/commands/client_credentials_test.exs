defmodule Authenticator.SignIn.Commands.ClientCredentialsTest do
  @moduledoc false

  use Authenticator.DataCase, async: true

  alias Authenticator.Ports.ResourceManagerMock
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, ClientAssertion, RefreshToken}
  alias Authenticator.SignIn.Commands.ClientCredentials, as: Command
  alias Authenticator.SignIn.Schemas.ApplicationAttempt

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
        client_secret: app.secret,
        ip_address: "45.232.192.12"
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
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
                "identity" => "application",
                "sub" => ^subject_id,
                "typ" => ^typ
              }} = AccessToken.verify_and_validate(access_token)

      assert %ApplicationAttempt{client_id: ^client_id} = Repo.one(ApplicationAttempt)
      assert %Session{jti: ^jti, type: "access_token"} = Repo.one(Session)
    end

    test "succeeds and generates a refresh_token" do
      scopes = RF.insert_list!(:scope, 3)
      app = RF.insert!(:client_application, grant_flows: ["client_credentials", "refresh_token"])

      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        "grant_type" => "client_credentials",
        "scope" => scope,
        "client_id" => client_id,
        "client_secret" => app.secret,
        "ip_address" => "45.232.192.12"
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      assert {:ok,
              %{
                access_token: access_token,
                refresh_token: refresh_token,
                expires_in: 7200,
                token_type: typ
              }} = Command.execute(input)

      assert {:ok, %{"jti" => ati}} = RefreshToken.verify_and_validate(access_token)

      assert {:ok,
              %{
                "aud" => ^client_id,
                "ati" => ^ati,
                "exp" => _,
                "iat" => _,
                "iss" => "WatcherEx",
                "jti" => jti,
                "nbf" => _,
                "typ" => ^typ
              }} = RefreshToken.verify_and_validate(refresh_token)

      assert %ApplicationAttempt{client_id: ^client_id} = Repo.one(ApplicationAttempt)

      assert [%Session{type: "access_token"}, %Session{jti: ^jti, type: "refresh_token"}] =
               Repo.all(Session)
    end

    test "succeeds using client_assertions and generates an access_token" do
      scopes = RF.insert_list!(:scope, 3)
      app = RF.insert!(:client_application, grant_flows: ["client_credentials"])
      public_key = RF.insert!(:public_key, client_application: app, value: get_public_key())

      signer = Joken.Signer.create("RS256", %{"pem" => get_private_key()})

      client_assertion =
        ClientAssertion.generate_and_sign!(
          %{"iss" => app.client_id, "aud" => "WatcherEx", "typ" => "Bearer"},
          signer
        )

      input = %{
        grant_type: "client_credentials",
        scope: scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        client_assertion: client_assertion,
        ip_address: "45.232.192.12"
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: public_key, scopes: scopes}}
      end)

      assert {:ok,
              %{
                access_token: access_token,
                refresh_token: nil,
                expires_in: 7200,
                token_type: _
              }} = Command.execute(input)

      assert is_binary(access_token)
    end

    test "succeeds using client_assertions and generates a refresh_token" do
      scopes = RF.insert_list!(:scope, 3)
      app = RF.insert!(:client_application, grant_flows: ["client_credentials", "refresh_token"])
      public_key = RF.insert!(:public_key, client_application: app, value: get_public_key())

      signer = Joken.Signer.create("RS256", %{"pem" => get_private_key()})

      client_assertion =
        ClientAssertion.generate_and_sign!(
          %{"iss" => app.client_id, "aud" => "WatcherEx", "typ" => "Bearer"},
          signer
        )

      input = %{
        "grant_type" => "client_credentials",
        "scope" => scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        "client_id" => app.client_id,
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => client_assertion,
        "ip_address" => "45.232.192.12"
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: public_key, scopes: scopes}}
      end)

      assert {:ok,
              %{
                access_token: _,
                refresh_token: refresh_token,
                expires_in: 7200,
                token_type: _
              }} = Command.execute(input)

      assert is_binary(refresh_token)
    end

    test "fails if params are invalid" do
      assert {:error, :invalid_params} == Command.execute(%{})

      assert {:error, changeset} = Command.execute(%{grant_type: "client_credentials"})

      assert %{
               client_assertion_type: ["can't be blank"],
               client_assertion: ["can't be blank"],
               client_id: ["can't be blank"],
               ip_address: ["can't be blank"],
               scope: ["can't be blank"]
             } == errors_on(changeset)
    end

    test "fails if client application do not exist" do
      input = %{
        grant_type: "client_credentials",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret",
        ip_address: "45.232.192.12"
      }

      expect(ResourceManagerMock, :get_identity, fn _ -> {:error, :not_found} end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application flow is not enabled" do
      input = %{
        grant_type: "client_credentials",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret",
        ip_address: "45.232.192.12"
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
        client_secret: "my-secret",
        ip_address: "45.232.192.12"
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
        client_secret: Ecto.UUID.generate(),
        ip_address: "45.232.192.12"
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
        client_secret: "my-secret",
        ip_address: "45.232.192.12"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, protocol: "saml")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end
  end
end
