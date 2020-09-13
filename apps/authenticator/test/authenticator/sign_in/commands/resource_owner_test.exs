defmodule Authenticator.SignIn.Commands.ResourceOwner do
  use ResourceManager.DataCase, async: true

  alias Authenticator.Sessions.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.ResourceOwner

  setup do
    scopes = insert_list!(:scope, 3)

    user = insert!(:user)
    app = insert!(:client_application)

    Enum.each(scopes, &insert!(:user_scope, scope: &1, user: user))
    Enum.each(scopes, &insert!(:client_application_scope, scope: &1, client_application: app))

    password = "MyPassw@rd234"
    hash = gen_hashed_password(password)
    insert!(:password, user: user, password_hash: hash)

    {:ok, user: user, app: app, password: password, scopes: scopes}
  end

  describe "#{ResourceOwner}.execute/1" do
    test "succeeds and generates an access_token", ctx do
      subject_id = ctx.user.id
      client_id = ctx.app.client_id
      client_name = ctx.app.name
      scopes = ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: scopes,
        client_id: client_id,
        client_secret: ctx.app.secret
      }

      assert {:ok, %{access_token: access_token, refresh_token: nil}} =
               ResourceOwner.execute(input)

      assert {:ok,
              %{
                "aud" => ^client_id,
                "azp" => ^client_name,
                "exp" => _,
                "iat" => _,
                "iss" => "WatcherEx",
                "jti" => _,
                "nbf" => _,
                "scope" => ^scopes,
                "sub" => ^subject_id,
                "typ" => "Bearer"
              }} = AccessToken.verify_and_validate(access_token)
    end

    test "succeeds and generates a refresh_token", ctx do
      app = insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])

      Enum.each(
        ctx.scopes,
        &insert!(:client_application_scope, scope: &1, client_application: app)
      )

      client_id = app.client_id
      scopes = ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: scopes,
        client_id: client_id,
        client_secret: app.secret
      }

      assert {:ok, %{access_token: access_token, refresh_token: refresh_token}} =
               ResourceOwner.execute(input)

      assert is_binary(access_token)

      assert {:ok,
              %{
                "aud" => ^client_id,
                "exp" => _,
                "iat" => _,
                "iss" => "WatcherEx",
                "jti" => _,
                "nbf" => _,
                "typ" => "Bearer"
              }} = RefreshToken.verify_and_validate(refresh_token)
    end

    test "fails if client application do not exist", ctx do
      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: Ecto.UUID.generate(),
        client_secret: ctx.app.secret
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end

    test "fails if client application is flow not enabled", ctx do
      app = insert!(:client_application, grant_flows: [])

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_secret: app.client_id
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end

    test "fails if client application is inactive", ctx do
      app = insert!(:client_application, status: "blocked")

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_secret: app.client_id
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end

    test "fails if client application secret do not match credential", ctx do
      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: ctx.app.client_id,
        client_secret: Ecto.UUID.generate()
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end

    test "fails if client application is not confidential", ctx do
      app = insert!(:client_application, access_type: "public")

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_secret: app.client_id
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end

    test "fails if client application protocol is not openid-connect", ctx do
      app = insert!(:client_application, protocol: "saml")

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_secret: app.client_id
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end

    test "fails if user do not exist", ctx do
      input = %{
        username: Ecto.UUID.generate(),
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: ctx.app.client_id,
        client_secret: ctx.app.secret
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end

    test "fails if user is inactive", ctx do
      user = insert!(:user, status: "blocked")

      input = %{
        username: user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: ctx.app.client_id,
        client_secret: ctx.app.client_id
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end

    test "fails if user password do not match credential", ctx do
      input = %{
        username: ctx.user.username,
        password: Ecto.UUID.generate(),
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: ctx.app.client_id,
        client_secret: ctx.app.secret
      }

      assert {:error, :unauthenticated} == ResourceOwner.execute(input)
    end
  end
end
