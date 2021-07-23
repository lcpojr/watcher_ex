defmodule Authenticator.SignIn.Commands.RefreshTokenTest do
  @moduledoc false

  use Authenticator.DataCase, async: true

  alias Authenticator.Ports.ResourceManagerMock
  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.Commands.RefreshToken, as: Command

  describe "#{Command}.execute/1" do
    test "succeeds and generates both tokens" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])

      subject_id = user.id
      client_id = app.client_id
      client_name = app.name
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      access_token_claims = %{
        "aud" => client_id,
        "azp" => app.name,
        "sub" => subject_id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => scope
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session, jti: jti, subject_id: subject_id, subject_type: "user", claims: claims)

      refresh_token_claims = %{
        "aud" => client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: id} ->
        assert user.id == id
        {:ok, user}
      end)

      assert {:ok,
              %{
                access_token: access_token,
                refresh_token: refresh_token,
                expires_in: 7200,
                token_type: typ
              }} = Command.execute(%{refresh_token: token, grant_type: "refresh_token"})

      assert %Session{jti: ^jti, status: "refreshed"} = Repo.get_by(Session, jti: jti)

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

      assert %Session{jti: ^jti, status: "active"} = Repo.get_by(Session, jti: jti)
    end

    test "succeeds even if session is expired" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])

      subject_id = user.id
      client_id = app.client_id
      client_name = app.name
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      access_token_claims = %{
        "aud" => client_id,
        "azp" => app.name,
        "sub" => subject_id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => scope
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session,
        jti: jti,
        subject_id: subject_id,
        subject_type: "user",
        claims: claims,
        status: "expired"
      )

      refresh_token_claims = %{
        "aud" => client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: id} ->
        assert user.id == id
        {:ok, user}
      end)

      assert {:ok,
              %{
                access_token: access_token,
                refresh_token: refresh_token,
                expires_in: 7200,
                token_type: typ
              }} = Command.execute(%{"refresh_token" => token, "grant_type" => "refresh_token"})

      assert %Session{jti: ^jti, status: "refreshed"} = Repo.get_by(Session, jti: jti)

      assert {:ok,
              %{
                "aud" => ^client_id,
                "azp" => ^client_name,
                "exp" => _,
                "iat" => _,
                "iss" => "WatcherEx",
                "jti" => jti,
                "nbf" => _,
                "identity" => "user",
                "scope" => ^scope,
                "sub" => ^subject_id,
                "typ" => ^typ
              }} = AccessToken.verify_and_validate(access_token)

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

      assert %Session{jti: ^jti, status: "active"} = Repo.get_by(Session, jti: jti)
    end

    test "fails if params are invalid" do
      assert {:error, :invalid_params} == Command.execute(%{})
      assert {:error, changeset} = Command.execute(%{grant_type: "refresh_token"})
      assert %{refresh_token: ["can't be blank"]} = errors_on(changeset)
    end

    test "fails if session does not exist" do
      app_id = Ecto.UUID.generate()
      user_id = Ecto.UUID.generate()

      access_token_claims = %{
        "aud" => app_id,
        "azp" => "My application",
        "sub" => user_id,
        "typ" => "Bearer",
        "scope" => "admin:read"
      }

      {:ok, _token, %{"jti" => jti}} = build_access_token(access_token_claims)

      refresh_token_claims = %{
        "aud" => app_id,
        "azp" => "My application",
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      assert {:error, :unauthenticated} ==
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})
    end

    test "fails if session was revoked" do
      app_id = Ecto.UUID.generate()
      user_id = Ecto.UUID.generate()

      access_token_claims = %{
        "aud" => app_id,
        "azp" => "My application",
        "sub" => user_id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => "admin:read"
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session,
        jti: jti,
        subject_id: user_id,
        subject_type: "user",
        claims: claims,
        status: "revoked"
      )

      refresh_token_claims = %{
        "aud" => app_id,
        "azp" => "My application",
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      assert {:error, :unauthenticated} ==
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})
    end

    test "fails if session already refreshed" do
      app_id = Ecto.UUID.generate()
      user_id = Ecto.UUID.generate()

      access_token_claims = %{
        "aud" => app_id,
        "azp" => "My application",
        "sub" => user_id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => "admin:read"
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session,
        jti: jti,
        subject_id: user_id,
        subject_type: "user",
        claims: claims,
        status: "refreshed"
      )

      refresh_token_claims = %{
        "aud" => app_id,
        "azp" => "My application",
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      assert {:error, :unauthenticated} ==
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})
    end

    test "fails if client application flow is not enabled" do
      user = RF.insert!(:user)
      app = RF.insert!(:client_application, grant_flows: ["resource_owner"])
      scopes = RF.insert_list!(:scope, 3)

      access_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "sub" => user.id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => scopes |> Enum.map(& &1.name) |> Enum.join(" ")
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session, jti: jti, subject_id: user.id, subject_type: "user", claims: claims)

      refresh_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, app} end)

      assert {:error, :unauthenticated} ==
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})
    end

    test "fails if client application protocol is not openid-connect" do
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          protocol: "saml",
          grant_flows: ["resource_owner", "refresh_token"]
        )

      scopes = RF.insert_list!(:scope, 3)

      access_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "sub" => user.id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => scopes |> Enum.map(& &1.name) |> Enum.join(" ")
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session, jti: jti, subject_id: user.id, subject_type: "user", claims: claims)

      refresh_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, app} end)

      assert {:error, :unauthenticated} ==
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})
    end

    test "fails if client application is inactive" do
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          status: "blocked",
          grant_flows: ["resource_owner", "refresh_token"]
        )

      scopes = RF.insert_list!(:scope, 3)

      access_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "sub" => user.id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => scopes |> Enum.map(& &1.name) |> Enum.join(" ")
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session, jti: jti, subject_id: user.id, subject_type: "user", claims: claims)

      refresh_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, app} end)

      assert {:error, :unauthenticated} ==
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})
    end

    test "fails if subject does not exist" do
      app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])
      scopes = RF.insert_list!(:scope, 3)

      subject_id = Ecto.UUID.generate()

      access_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "sub" => subject_id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => scopes |> Enum.map(& &1.name) |> Enum.join(" ")
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session,
        jti: jti,
        subject_id: subject_id,
        subject_type: "user",
        claims: claims
      )

      refresh_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, app} end)
      expect(ResourceManagerMock, :get_identity, fn _ -> {:error, :not_found} end)

      assert {:error, :unauthenticated} ==
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})
    end

    test "fails if subject is inactive" do
      user = RF.insert!(:user, status: "blocked")
      app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])
      scopes = RF.insert_list!(:scope, 3)

      access_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "sub" => user.id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => scopes |> Enum.map(& &1.name) |> Enum.join(" ")
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session,
        jti: jti,
        subject_id: user.id,
        subject_type: "user",
        claims: claims
      )

      refresh_token_claims = %{
        "aud" => app.client_id,
        "azp" => app.name,
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, app} end)
      expect(ResourceManagerMock, :get_identity, fn _ -> {:ok, user} end)

      assert {:error, :unauthenticated} ==
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})
    end
  end
end
