defmodule Authenticator.SignIn.Commands.RefreshTokenTest do
  use Authenticator.DataCase, async: true

  alias Authenticator.Sessions.Tokens.{AccessToken, RefreshToken}
  alias Authenticator.SignIn.RefreshToken, as: Command
  alias Authenticator.Sessions.Schemas.Session

  setup do
    scopes = RF.insert_list!(:scope, 3)
    user = RF.insert!(:user)
    app = RF.insert!(:client_application, grant_flows: ["resource_owner", "refresh_token"])

    Enum.each(scopes, &RF.insert!(:user_scope, scope: &1, user: user))
    Enum.each(scopes, &RF.insert!(:client_application_scope, scope: &1, client_application: app))

    {:ok, user: user, app: app, scopes: scopes}
  end

  describe "#{RefreshToken}.execute/1" do
    test "succeeds and generates both tokens", ctx do
      subject_id = ctx.user.id
      client_id = ctx.app.client_id
      client_name = ctx.app.name
      scopes = ctx.scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      access_token_claims = %{
        "aud" => ctx.app.client_id,
        "azp" => ctx.app.name,
        "sub" => ctx.user.id,
        "typ" => "Bearer",
        "scope" => scopes
      }

      {:ok, _token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)
      insert!(:session, jti: jti, subject_id: ctx.user.id, subject_type: "user", claims: claims)

      refresh_token_claims = %{
        "aud" => ctx.app.client_id,
        "azp" => ctx.app.name,
        "typ" => "Bearer",
        "ati" => jti
      }

      {:ok, token, _} = build_refresh_token(refresh_token_claims)

      assert {:ok, %{access_token: access_token, refresh_token: refresh_token}} =
               Command.execute(%{refresh_token: token, grant_type: "refresh_token"})

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
                "scope" => ^scopes,
                "sub" => ^subject_id,
                "typ" => "Bearer"
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
                "typ" => "Bearer"
              }} = RefreshToken.verify_and_validate(refresh_token)

      assert %Session{jti: ^jti, status: "active"} = Repo.get_by(Session, jti: jti)
    end
  end
end
