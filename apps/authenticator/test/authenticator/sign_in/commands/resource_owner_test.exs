defmodule Authenticator.SignIn.Commands.ResourceOwnerTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.Ports.ResourceManagerMock
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.Commands.ResourceOwner, as: Command

  describe "#{Command}.execute/1" do
    test "succeeds and generates an access_token" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      app = RF.insert!(:client_application)
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      subject_id = user.id
      client_id = app.client_id
      client_name = app.name
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        username: user.username,
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: scope,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: username} ->
        assert user.username == username
        {:ok, %{user | password: password, scopes: scopes}}
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
      user = RF.insert!(:user)
      app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        username: user.username,
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: scope,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: username} ->
        assert user.username == username
        {:ok, %{user | password: password, scopes: scopes}}
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
                  username: {"can't be blank", [validation: :required]},
                  password: {"can't be blank", [validation: :required]},
                  client_id: {"can't be blank", [validation: :required]},
                  client_secret: {"can't be blank", [validation: :required]},
                  scope: {"can't be blank", [validation: :required]}
                ]
              }} = Command.execute(%{grant_type: "password"})
    end

    test "fails if client application do not exist" do
      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ -> {:error, :not_found} end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application flow is not enabled" do
      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
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
      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, status: "blocked")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application secret do not match credential" do
      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: Ecto.UUID.generate()
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, secret: "another-secret")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application is not confidential" do
      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, access_type: "public")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application protocol is not openid-connect" do
      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, protocol: "saml")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if user do not exist" do
      app = RF.insert!(:client_application)

      input = %{
        username: Ecto.UUID.generate(),
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: _} -> {:ok, app} end)

      expect(ResourceManagerMock, :get_identity, fn %{username: _} -> {:error, :not_found} end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if user is inactive" do
      app = RF.insert!(:client_application)

      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: _} -> {:ok, app} end)

      expect(ResourceManagerMock, :get_identity, fn %{username: _} ->
        {:ok, RF.insert!(:user, status: "blocked")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if user password do not match credential" do
      app = RF.insert!(:client_application)

      input = %{
        username: "my-username",
        password: Ecto.UUID.generate(),
        grant_type: "password",
        scope: "admin:read",
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: _} -> {:ok, app} end)

      expect(ResourceManagerMock, :get_identity, fn %{username: _} ->
        user = RF.insert!(:user, status: "blocked")
        hash = RF.gen_hashed_password("AnotherPassword")
        password = RF.insert!(:password, user: user, password_hash: hash)
        {:ok, %{user | password: password}}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end
  end
end
