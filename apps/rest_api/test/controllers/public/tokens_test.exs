defmodule RestAPI.Controllers.Public.TokensTest do
  use RestAPI.ConnCase, async: true

  alias Authenticator.SignIn.Inputs.{RefreshToken, ResourceOwner}
  alias RestAPI.Ports.AuthenticatorMock

  @sign_in_endpoint "/api/v1/auth/protocol/openid-connect/token"

  describe "POST #{@sign_in_endpoint}" do
    test "suceeds in Resource Owner Flow if params are valid", %{conn: conn} do
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

      assert %{"access_token" => _, "refresh_token" => _, "token_type" => _, "expires_in" => _} =
               conn
               |> post(@sign_in_endpoint, params)
               |> json_response(200)
    end

    test "suceeds in Refresh Token Flow if params are valid", %{conn: conn} do
      params = %{
        "refresh_token" => "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
        "grant_type" => "refresh_token"
      }

      expect(AuthenticatorMock, :sign_in_refresh_token, fn _input ->
        {:ok, success_payload()}
      end)

      assert %{"access_token" => _, "refresh_token" => _, "token_type" => _, "expires_in" => _} =
               conn
               |> post(@sign_in_endpoint, params)
               |> json_response(200)
    end

    test "fails in Resource Owner Flow if params are invalid", %{conn: conn} do
      expect(AuthenticatorMock, :sign_in_resource_owner, fn input when is_map(input) ->
        ResourceOwner.cast_and_apply(input)
      end)

      assert %{
               "scope" => ["can't be blank"],
               "client_id" => ["can't be blank"],
               "client_secret" => ["can't be blank"],
               "password" => ["can't be blank"],
               "username" => ["can't be blank"]
             } ==
               conn
               |> post(@sign_in_endpoint, %{"grant_type" => "password"})
               |> json_response(400)
    end

    test "fails in Refresh Token Flow if params are invalid", %{conn: conn} do
      expect(AuthenticatorMock, :sign_in_refresh_token, fn input when is_map(input) ->
        RefreshToken.cast_and_apply(input)
      end)

      assert %{"refresh_token" => ["can't be blank"]} ==
               conn
               |> post(@sign_in_endpoint, %{"grant_type" => "refresh_token"})
               |> json_response(400)
    end
  end

  defp success_payload do
    %{
      access_token: "access_token",
      refresh_token: "refresh_token",
      token_type: "Bearer",
      expires_in: 100_000
    }
  end
end
