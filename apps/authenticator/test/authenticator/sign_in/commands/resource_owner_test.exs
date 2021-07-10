defmodule Authenticator.SignIn.Commands.ResourceOwnerTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.Ports.ResourceManagerMock
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, ClientAssertion, RefreshToken}
  alias Authenticator.SignIn.Commands.ResourceOwner, as: Command
  alias Authenticator.SignIn.Schemas.UserAttempt

  describe "#{Command}.execute/1" do
    test "succeeds and generates an access_token" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      app = RF.insert!(:client_application)
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      username = user.username
      subject_id = user.id
      client_id = app.client_id
      client_name = app.name
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        username: username,
        password: "MyPassw@rd234",
        grant_type: "password",
        ip_address: "45.232.192.12",
        scope: scope,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: input_username} ->
        assert username == input_username
        {:ok, %{user | password: password, totp: nil, scopes: scopes}}
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

      assert %UserAttempt{username: ^username} = Repo.one(UserAttempt)
      assert %Session{jti: ^jti} = Repo.one(Session)
    end

    test "succeeds and generates an access_token validating totp" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      totp = RF.insert!(:totp, user: user)
      app = RF.insert!(:client_application)
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      username = user.username
      subject_id = user.id
      client_id = app.client_id
      client_name = app.name
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        username: username,
        password: "MyPassw@rd234",
        otp: "1234",
        grant_type: "password",
        ip_address: "45.232.192.12",
        scope: scope,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: input_username} ->
        assert username == input_username
        {:ok, %{user | password: password, totp: totp, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :valid_totp?, fn %{id: totp_id}, "1234" ->
        assert totp.id == totp_id
        true
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

      assert %UserAttempt{username: ^username} = Repo.one(UserAttempt)
      assert %Session{jti: ^jti} = Repo.one(Session)
    end

    test "succeeds and generates a refresh_token" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      username = user.username
      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        "username" => username,
        "password" => "MyPassw@rd234",
        "grant_type" => "password",
        "ip_address" => "45.232.192.12",
        "scope" => scope,
        "client_id" => client_id,
        "client_secret" => app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: input_username} ->
        assert username == input_username
        {:ok, %{user | password: password, totp: nil, scopes: scopes}}
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

      assert %UserAttempt{username: ^username} = Repo.one(UserAttempt)
      assert %Session{jti: ^jti} = Repo.one(Session)
    end

    test "succeeds and generates a refresh_token validating totp" do
      scopes = RF.insert_list!(:scope, 3)
      %{username: username} = user = RF.insert!(:user)
      totp = RF.insert!(:totp, user: user)
      %{client_id: client_id} = app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      username = user.username
      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        "username" => username,
        "password" => "MyPassw@rd234",
        "otp" => "1234",
        "grant_type" => "password",
        "ip_address" => "45.232.192.12",
        "scope" => scope,
        "client_id" => client_id,
        "client_secret" => app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: input_username} ->
        assert username == input_username
        {:ok, %{user | password: password, totp: totp, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :valid_totp?, fn %{id: totp_id}, "1234" ->
        assert totp.id == totp_id
        true
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

      assert %UserAttempt{username: ^username} = Repo.one(UserAttempt)
      assert %Session{jti: ^jti} = Repo.one(Session)
    end

    test "succeeds using client_assertions and generates an access_token" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      app = RF.insert!(:client_application, access_type: "confidential")
      public_key = RF.insert!(:public_key, client_application: app, value: get_public_key())
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      signer = Joken.Signer.create("RS256", %{"pem" => get_private_key()})

      client_assertion =
        ClientAssertion.generate_and_sign!(
          %{"iss" => app.client_id, "aud" => "WatcherEx", "typ" => "Bearer"},
          signer
        )

      input = %{
        username: user.username,
        password: "MyPassw@rd234",
        grant_type: "password",
        ip_address: "45.232.192.12",
        scope: scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_assertion_type: "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        client_assertion: client_assertion
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: public_key, scopes: scopes}}
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
                token_type: _
              }} = Command.execute(input)

      assert is_binary(access_token)
    end

    test "succeeds using client_assertions and generates a refresh_token" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          access_type: "confidential",
          grant_flows: ["resource_owner", "refresh_token"]
        )

      public_key = RF.insert!(:public_key, client_application: app, value: get_public_key())
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      signer = Joken.Signer.create("RS256", %{"pem" => get_private_key()})

      client_assertion =
        ClientAssertion.generate_and_sign!(
          %{"iss" => app.client_id, "aud" => "WatcherEx", "typ" => "Bearer"},
          signer
        )

      input = %{
        "username" => user.username,
        "password" => "MyPassw@rd234",
        "grant_type" => "password",
        "ip_address" => "45.232.192.12",
        "scope" => scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        "client_id" => app.client_id,
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => client_assertion
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: public_key, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: username} ->
        assert user.username == username
        {:ok, %{user | password: password, scopes: scopes}}
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
      assert {:error, changeset} = Command.execute(%{grant_type: "password"})

      assert %{
               client_assertion_type: ["can't be blank"],
               client_assertion: ["can't be blank"],
               username: ["can't be blank"],
               password: ["can't be blank"],
               client_id: ["can't be blank"],
               ip_address: ["can't be blank"],
               scope: ["can't be blank"]
             } = errors_on(changeset)

      assert {:error, changeset} = Command.execute(%{"grant_type" => "password"})

      assert %{
               client_assertion_type: ["can't be blank"],
               client_assertion: ["can't be blank"],
               username: ["can't be blank"],
               password: ["can't be blank"],
               client_id: ["can't be blank"],
               ip_address: ["can't be blank"],
               scope: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "fails if client application do not exist" do
      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        ip_address: "45.232.192.12",
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
        ip_address: "45.232.192.12",
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
        ip_address: "45.232.192.12",
        client_id: Ecto.UUID.generate(),
        client_secret: "my-secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, status: "blocked")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application secret do not match credential" do
      user = RF.insert!(:user)
      app = RF.insert!(:client_application, access_type: "confidential", secret: "another-secret")

      input = %{
        username: user.username,
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        ip_address: "45.232.192.12",
        client_id: Ecto.UUID.generate(),
        client_secret: Ecto.UUID.generate()
      }

      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, app} end)
      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, user} end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application protocol is not openid-connect" do
      input = %{
        username: "my-username",
        password: "MyPassw@rd234",
        grant_type: "password",
        scope: "admin:read",
        ip_address: "45.232.192.12",
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
        ip_address: "45.232.192.12",
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil}}
      end)

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
        ip_address: "45.232.192.12",
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil}}
      end)

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
        ip_address: "45.232.192.12",
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: _} ->
        user = RF.insert!(:user)
        hash = RF.gen_hashed_password("AnotherPassword")
        password = RF.insert!(:password, user: user, password_hash: hash)
        {:ok, %{user | password: password}}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if user totp do not match credential" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      totp = RF.insert!(:totp, user: user)
      app = RF.insert!(:client_application)
      hash = RF.gen_hashed_password("MyPassw@rd234")
      password = RF.insert!(:password, user: user, password_hash: hash)

      username = user.username
      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        username: username,
        password: "MyPassw@rd234",
        otp: "4321",
        grant_type: "password",
        ip_address: "45.232.192.12",
        scope: scope,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{username: input_username} ->
        assert username == input_username
        {:ok, %{user | password: password, totp: totp, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :valid_totp?, fn %{id: totp_id}, "4321" ->
        assert totp.id == totp_id
        false
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end
  end
end
