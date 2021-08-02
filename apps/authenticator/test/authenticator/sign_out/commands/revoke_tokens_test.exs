defmodule Authenticator.SignOut.Commands.RevokeTokensTest do
  @moduledoc false

  use Authenticator.DataCase, async: true

  alias Authenticator.SignOut.Commands.Inputs.RevokeTokens, as: Input
  alias Authenticator.SignOut.Commands.RevokeTokens, as: Commands

  describe "#{Commands}.execute/1" do
    setup do
      scopes = RF.insert_list!(:scope, 3)
      user = RF.insert!(:user)
      app = RF.insert!(:client_application)
      scope = scopes |> Enum.map(& &1.name) |> Enum.join(" ")

      {:ok, user: user, app: app, scope: scope}
    end

    test "succeeds and invalidates access token", ctx do
      access_token_claims = %{
        "aud" => ctx.app.client_id,
        "azp" => ctx.app.name,
        "sub" => ctx.user.id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => ctx.scope
      }

      {:ok, access_token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      session =
        insert!(
          :session,
          jti: jti,
          subject_id: ctx.user.id,
          subject_type: "user",
          claims: claims
        )

      assert {:ok, {%{id: id, status: "revoked"}, nil}} =
               Commands.execute(%Input{access_token: access_token})

      assert session.id == id
    end

    test "fails if session not active", ctx do
      access_token_claims = %{
        "aud" => ctx.app.client_id,
        "azp" => ctx.app.name,
        "sub" => ctx.user.id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => ctx.scope
      }

      {:ok, access_token, %{"jti" => jti} = claims} = build_access_token(access_token_claims)

      insert!(:session,
        jti: jti,
        subject_id: ctx.user.id,
        subject_type: "user",
        claims: claims,
        status: "revoked"
      )

      assert {:error, :not_active} == Commands.execute(%Input{access_token: access_token})
    end

    test "fails if session not found", ctx do
      access_token_claims = %{
        "aud" => ctx.app.client_id,
        "azp" => ctx.app.name,
        "sub" => ctx.user.id,
        "typ" => "Bearer",
        "identity" => "user",
        "scope" => ctx.scope
      }

      {:ok, access_token, _claims} = build_access_token(access_token_claims)

      assert {:error, :anauthenticated} == Commands.execute(%Input{access_token: access_token})
    end
  end
end
