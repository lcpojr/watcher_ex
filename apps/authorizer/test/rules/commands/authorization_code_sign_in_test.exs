defmodule Authorizer.SignIn.Commands.AuthorizationCodeTest do
  @moduledoc false

  use Authorizer.DataCase, async: true

  alias Authenticator.Sessions.Tokens.AuthorizationCode
  alias Authorizer.Ports.ResourceManagerMock
  alias Authorizer.Rules.Commands.AuthorizationCodeSignIn, as: Command
  alias Authorizer.Rules.Commands.Inputs.AuthorizationCodeSignIn, as: Input

  describe "#{Command}.execute/1" do
    test "succeeds and generates the authorization code" do
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
      redirect_uri = app.redirect_uri
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %Input{
        client_id: app.client_id,
        response_type: "code",
        redirect_uri: app.redirect_uri,
        scope: scope,
        authorized: true
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
                authorization_code: authorization_code,
                expires_in: 7200,
                token_type: typ
              }} = Command.execute(input, user.id)

      assert {:ok,
              %{
                "aud" => ^client_id,
                "azp" => ^client_name,
                "exp" => _,
                "iat" => _,
                "iss" => "WatcherEx",
                "jti" => _,
                "nbf" => _,
                "scope" => ^scope,
                "identity" => "user",
                "redirect_uri" => ^redirect_uri,
                "sub" => ^subject_id,
                "typ" => ^typ
              }} = AuthorizationCode.verify_and_validate(authorization_code)
    end

    test "fails if input not authorized by the user" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %Input{
        client_id: app.client_id,
        response_type: "code",
        redirect_uri: app.redirect_uri,
        scope: scope,
        authorized: false
      }

      assert {:error, :unauthorized} == Command.execute(input, user.id)
    end

    test "fails if client application not found" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %Input{
        client_id: Ecto.UUID.generate(),
        response_type: "code",
        redirect_uri: "https://redirect-test.com",
        scope: scope,
        authorized: true
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: _} ->
        {:error, :not_found}
      end)

      assert {:error, :unauthorized} == Command.execute(input, user.id)
    end

    test "fails if authorization code flow not enabled" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          redirect_uri: "https://redirect-test.com"
        )

      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %Input{
        client_id: app.client_id,
        response_type: "code",
        redirect_uri: app.redirect_uri,
        scope: scope,
        authorized: true
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      assert {:error, :unauthorized} == Command.execute(input, user.id)
    end

    test "fails if client is not active" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          status: "inactive",
          redirect_uri: "https://redirect-test.com"
        )

      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %Input{
        client_id: app.client_id,
        response_type: "code",
        redirect_uri: app.redirect_uri,
        scope: scope,
        authorized: true
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      assert {:error, :unauthorized} == Command.execute(input, user.id)
    end

    test "fails if client redirect uri is different" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)

      app =
        RF.insert!(:client_application,
          redirect_uri: "https://redirect-test2.com"
        )

      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %Input{
        client_id: app.client_id,
        response_type: "code",
        redirect_uri: app.redirect_uri,
        scope: scope,
        authorized: true
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      assert {:error, :unauthorized} == Command.execute(input, user.id)
    end

    test "fails if user not found" do
      scopes = RF.insert_list!(:scope, 3)

      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %Input{
        client_id: app.client_id,
        response_type: "code",
        redirect_uri: app.redirect_uri,
        scope: scope,
        authorized: true
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: _} ->
        {:error, :not_found}
      end)

      assert {:error, :unauthorized} == Command.execute(input, Ecto.UUID.generate())
    end

    test "fails if user not active" do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user, status: "inactive")

      app =
        RF.insert!(:client_application,
          grant_flows: ["authorization_code"],
          redirect_uri: "https://redirect-test.com"
        )

      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %Input{
        client_id: app.client_id,
        response_type: "code",
        redirect_uri: app.redirect_uri,
        scope: scope,
        authorized: true
      }

      expect(ResourceManagerMock, :get_identity, fn %{client_id: client_id} ->
        assert app.client_id == client_id
        {:ok, %{app | public_key: nil, scopes: scopes}}
      end)

      expect(ResourceManagerMock, :get_identity, fn %{id: id} ->
        assert user.id == id
        {:ok, %{user | scopes: scopes}}
      end)

      assert {:error, :unauthorized} == Command.execute(input, user.id)
    end
  end
end
