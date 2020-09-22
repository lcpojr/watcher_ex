defmodule RestAPI.Controllers.TokensTest do
  use RestAPI.ConnCase, async: true

  alias RestAPI.Ports.AuthenticatorMock

  describe "POST /api/v1/auth/protocol/openid-connect/token" do
    setup do
      {:ok, url: "/api/v1/auth/protocol/openid-connect/token"}
    end

    test "suceeds in Resource Owner Flow if params are valid", %{conn: conn, url: url} do
      params = %{
        "username" => "my-username",
        "password" => "my-password",
        "grant_type" => "password",
        "scope" => "admin:read admin:write",
        "client_id" => "2e455bb1-0604-4812-9756-36f7ab23b8d9",
        "client_secret" => "w3MehAvgztbMYpnhneVLQhkoZbxAXBGUCFe"
      }

      expect(AuthenticatorMock, :sign_in_resource_owner, fn _input ->
        {:ok, success_payload()}
      end)

      assert %{"access_token" => _, "refresh_token" => _, "scope" => _, "expires_at" => _} =
               conn
               |> post(url, params)
               |> json_response(200)
    end

    test "suceeds in Refresh Token Flow if params are valid", %{conn: conn, url: url} do
      params = %{
        "refresh_token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
        "grant_type" => "refresh_token"
      }

      expect(AuthenticatorMock, :sign_in_refresh_token, fn _input ->
        {:ok, success_payload()}
      end)

      assert %{"access_token" => _, "refresh_token" => _, "scope" => _, "expires_at" => _} =
               conn
               |> post(url, params)
               |> json_response(200)
    end

    test "fails in Resource Owner Flow if params are invalid", %{conn: conn, url: url} do
      expect(AuthenticatorMock, :sign_in_resource_owner, fn input when is_map(input) ->
        Authenticator.SignIn.Inputs.ResourceOwner.cast_and_apply(input)
      end)

      assert %{
               "scope" => ["can't be blank"],
               "client_id" => ["can't be blank"],
               "client_secret" => ["can't be blank"],
               "password" => ["can't be blank"],
               "username" => ["can't be blank"]
             } ==
               conn
               |> post(url, %{"grant_type" => "password"})
               |> json_response(400)
    end

    test "fails in Refresh Token Flow if params are invalid", %{conn: conn, url: url} do
      expect(AuthenticatorMock, :sign_in_refresh_token, fn input when is_map(input) ->
        Authenticator.SignIn.Inputs.RefreshToken.cast_and_apply(input)
      end)

      assert %{"refresh_token" => ["can't be blank"]} ==
               conn
               |> post(url, %{"grant_type" => "refresh_token"})
               |> json_response(400)
    end
  end

  defp success_payload do
    %{
      access_token: "access_token",
      refresh_token: "refresh_token",
      scope: "admin:read",
      expires_at: NaiveDateTime.utc_now()
    }
  end
end
