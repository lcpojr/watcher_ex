defmodule Authenticator.SignIn.Commands.AuthorizationCodeTest do
  @moduledoc false

  use Authenticator.DataCase, async: true

  alias Authenticator.Ports.ResourceManagerMock
  alias Authenticator.Sessions.Schemas.Session

  alias Authenticator.Sessions.Tokens.{
    AccessToken,
    ClientAssertion,
    RefreshToken
  }

  alias Authenticator.SignIn.Commands.AuthorizationCode, as: Command

  describe "#{Command}.execute/1" do
    test "succeeds and generates an access_token" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      subject_id = user.id
      client_id = app.client_id
      client_name = app.name
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      authorization_code_token_claims = %{
        "aud" => client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "sub" => user.id,
        "identity" => "user",
        "redirect_uri" => app.redirect_uri,
        "scope" => scope
      }

      {:ok, token, _} = build_authorization_code_token(authorization_code_token_claims)

      input = %{
        code: token,
        grant_type: "authorization_code",
        redirect_uri: app.redirect_uri,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: id} ->
        assert user.id == id
        {:ok, %{user | scopes: scopes}}
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

      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code", "refresh_token"],
          redirect_uri: "https://redirect-test.com"
        )

      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      authorization_code_token_claims = %{
        "aud" => client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "sub" => user.id,
        "identity" => "user",
        "redirect_uri" => app.redirect_uri,
        "scope" => scope
      }

      {:ok, token, _} = build_authorization_code_token(authorization_code_token_claims)

      input = %{
        code: token,
        grant_type: "authorization_code",
        redirect_uri: app.redirect_uri,
        client_id: client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: id} ->
        assert user.id == id
        {:ok, %{user | scopes: scopes}}
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

    test "succeeds using client_assertions and generates an access_token" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com",
          access_type: "confidential"
        )

      public_key = RF.insert!(:public_key, client_application: app, value: get_public_key())

      signer = Joken.Signer.create("RS256", %{"pem" => get_private_key()})

      client_assertion =
        ClientAssertion.generate_and_sign!(
          %{"iss" => app.client_id, "aud" => "WatcherEx", "typ" => "Bearer"},
          signer
        )

      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      authorization_code_token_claims = %{
        "aud" => client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "sub" => user.id,
        "identity" => "user",
        "redirect_uri" => app.redirect_uri,
        "scope" => scope
      }

      {:ok, token, _} = build_authorization_code_token(authorization_code_token_claims)

      input = %{
        "code" => token,
        "grant_type" => "authorization_code",
        "redirect_uri" => app.redirect_uri,
        "client_id" => client_id,
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => client_assertion
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: public_key, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: id} ->
        assert user.id == id
        {:ok, %{user | scopes: scopes}}
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
          redirect_uri: "https://redirect-test.com",
          grant_flows: ["authorization_code", "refresh_token"]
        )

      public_key = RF.insert!(:public_key, client_application: app, value: get_public_key())

      signer = Joken.Signer.create("RS256", %{"pem" => get_private_key()})

      client_assertion =
        ClientAssertion.generate_and_sign!(
          %{"iss" => app.client_id, "aud" => "WatcherEx", "typ" => "Bearer"},
          signer
        )

      client_id = app.client_id
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      authorization_code_token_claims = %{
        "aud" => client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "sub" => user.id,
        "identity" => "user",
        "redirect_uri" => app.redirect_uri,
        "scope" => scope
      }

      {:ok, token, _} = build_authorization_code_token(authorization_code_token_claims)

      input = %{
        "code" => token,
        "grant_type" => "authorization_code",
        "redirect_uri" => app.redirect_uri,
        "client_id" => client_id,
        "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        "client_assertion" => client_assertion
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: public_key, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: id} ->
        assert user.id == id
        {:ok, %{user | scopes: scopes}}
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
      assert {:error, changeset} = Command.execute(%{grant_type: "authorization_code"})

      assert %{
               client_assertion: ["can't be blank"],
               client_assertion_type: ["can't be blank"],
               client_id: ["can't be blank"],
               code: ["can't be blank"]
             } = errors_on(changeset)

      assert {:error, changeset} = Command.execute(%{"grant_type" => "authorization_code"})

      assert %{
               client_assertion: ["can't be blank"],
               client_assertion_type: ["can't be blank"],
               client_id: ["can't be blank"],
               code: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "fails if client application do not exist" do
      input = %{
        code: "token",
        grant_type: "authorization_code",
        redirect_uri: "https://redirect-test.com",
        client_id: Ecto.UUID.generate(),
        client_secret: "secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ -> {:error, :not_found} end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application flow is not enabled" do
      input = %{
        code: "token",
        grant_type: "authorization_code",
        redirect_uri: "https://redirect-test.com",
        client_id: Ecto.UUID.generate(),
        client_secret: "secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, grant_flows: [])}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application is inactive" do
      app =
        RF.insert!(:client_application,
          status: "blocked",
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      input = %{
        code: "token",
        grant_type: "authorization_code",
        redirect_uri: app.redirect_uri,
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, app}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client_id is different from authorized" do
      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      authorization_code_token_claims = %{
        "aud" => Ecto.UUID.generate(),
        "azp" => app.name,
        "typ" => "Bearer",
        "sub" => Ecto.UUID.generate(),
        "identity" => "user",
        "redirect_uri" => app.redirect_uri,
        "scope" => "scope"
      }

      {:ok, token, _} = build_authorization_code_token(authorization_code_token_claims)

      input = %{
        code: token,
        grant_type: "authorization_code",
        redirect_uri: app.redirect_uri,
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, app}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if redirect_uri is different from authorized" do
      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      authorization_code_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "sub" => Ecto.UUID.generate(),
        "identity" => "user",
        "redirect_uri" => "https://another-redirect-test.com",
        "scope" => "scope"
      }

      {:ok, token, _} = build_authorization_code_token(authorization_code_token_claims)

      input = %{
        code: token,
        grant_type: "authorization_code",
        redirect_uri: app.redirect_uri,
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, app}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application secret do not match credential" do
      app = RF.insert!(:client_application, access_type: "confidential", secret: "another-secret")

      input = %{
        code: "token",
        grant_type: "authorization_code",
        redirect_uri: "https://redirect-test.com",
        client_id: Ecto.UUID.generate(),
        client_secret: "secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, app} end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application protocol is not openid-connect" do
      input = %{
        code: "token",
        grant_type: "authorization_code",
        redirect_uri: "https://redirect-test.com",
        client_id: Ecto.UUID.generate(),
        client_secret: "secret"
      }

      expect(ResourceManagerMock, :get_identity, fn _ ->
        {:ok, RF.insert!(:client_application, protocol: "saml")}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if user do not exist" do
      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      authorization_code_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "sub" => Ecto.UUID.generate(),
        "identity" => "user",
        "redirect_uri" => app.redirect_uri,
        "scope" => "scope"
      }

      {:ok, token, _} = build_authorization_code_token(authorization_code_token_claims)

      input = %{
        code: token,
        grant_type: "authorization_code",
        redirect_uri: app.redirect_uri,
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: _} -> {:error, :not_found} end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if user is inactive" do
      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      user = RF.insert!(:user, status: "blocked")

      authorization_code_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "sub" => user.id,
        "identity" => "user",
        "redirect_uri" => app.redirect_uri,
        "scope" => "scope"
      }

      {:ok, token, _} = build_authorization_code_token(authorization_code_token_claims)

      input = %{
        code: token,
        grant_type: "authorization_code",
        redirect_uri: app.redirect_uri,
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: _} ->
        {:ok, user}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if authorization code is invalid" do
      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      input = %{
        code: "token",
        grant_type: "authorization_code",
        redirect_uri: app.redirect_uri,
        client_id: app.client_id,
        client_secret: app.secret
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil}}
      end)

      assert {:error, :unauthenticated} == Command.execute(input)
    end
  end
end
