defmodule Authenticator.SignIn.Commands.ResourceOwnerTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.Sessions.Schemas.Session
  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.Commands.ResourceOwner, as: Command

  setup do
    scopes = RF.insert_list!(:scope, 3)

    user = RF.insert!(:user)
    app = RF.insert!(:client_application)

    Enum.each(scopes, &RF.insert!(:user_scope, scope: &1, user: user))
    Enum.each(scopes, &RF.insert!(:client_application_scope, scope: &1, client_application: app))

    password = "MyPassw@rd234"
    hash = RF.gen_hashed_password(password)
    RF.insert!(:password, user: user, password_hash: hash)

    {:ok, user: user, app: app, password: password, scopes: scopes}
  end

  describe "#{Command}.execute/1" do
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

      assert {:ok, %{access_token: access_token, refresh_token: nil}} = Command.execute(input)

      assert {:ok,
              %{
                "aud" => ^client_id,
                "azp" => ^client_name,
                "exp" => _,
                "iat" => _,
                "iss" => "WatcherEx",
                "jti" => jti,
                "nbf" => _,
                "scope" => ^scopes,
                "sub" => ^subject_id,
                "typ" => "Bearer"
              }} = AccessToken.verify_and_validate(access_token)

      assert %Session{jti: ^jti} = Repo.one(Session)
    end

    test "succeeds and generates a refresh_token", ctx do
      app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])

      Enum.each(
        ctx.scopes,
        &RF.insert!(:client_application_scope, scope: &1, client_application: app)
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
               Command.execute(input)

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
                "typ" => "Bearer"
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

    test "fails if client application do not exist", ctx do
      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: Ecto.UUID.generate(),
        client_secret: ctx.app.secret
      }

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application flow is not enabled", ctx do
      app = RF.insert!(:client_application, grant_flows: [])

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_secret: app.client_id
      }

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application is inactive", ctx do
      app = RF.insert!(:client_application, status: "blocked")

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_secret: app.client_id
      }

      assert {:error, :unauthenticated} == Command.execute(input)
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

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application is not confidential", ctx do
      app = RF.insert!(:client_application, access_type: "public")

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_secret: app.client_id
      }

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if client application protocol is not openid-connect", ctx do
      app = RF.insert!(:client_application, protocol: "saml")

      input = %{
        username: ctx.user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: app.client_id,
        client_secret: app.client_id
      }

      assert {:error, :unauthenticated} == Command.execute(input)
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

      assert {:error, :unauthenticated} == Command.execute(input)
    end

    test "fails if user is inactive", ctx do
      user = RF.insert!(:user, status: "blocked")

      input = %{
        username: user.username,
        password: ctx.password,
        grant_type: "password",
        scope: ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" "),
        client_id: ctx.app.client_id,
        client_secret: ctx.app.client_id
      }

      assert {:error, :unauthenticated} == Command.execute(input)
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

      assert {:error, :unauthenticated} == Command.execute(input)
    end
  end
end
