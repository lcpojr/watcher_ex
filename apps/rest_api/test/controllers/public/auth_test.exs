defmodule RestAPI.Controllers.Public.AuthTest do
  use RestAPI.ConnCase, async: true

  alias Authenticator.SignIn.Inputs.{ClientCredentials, RefreshToken, ResourceOwner}
  alias RestAPI.Ports.AuthenticatorMock

  @token_endpoint "/api/v1/auth/protocol/openid-connect/token"
  @logout_endpoint "api/v1/auth/protocol/openid-connect/logout"
  @logout_all_endpoint "api/v1/auth/protocol/openid-connect/logout-all-sessions"

  describe "POST #{@token_endpoint}" do
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
               |> post(@token_endpoint, params)
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
               |> post(@token_endpoint, params)
               |> json_response(200)
    end

    test "suceeds in Client Credentials Flow if params are valid", %{conn: conn} do
      params = %{
        "grant_type" => "client_credentials",
        "scope" => "admin:read admin:write",
        "client_id" => "2e455bb1-0604-4812-9756-36f7ab23b8d9",
        "client_secret" => "w3MehAvgztbMYpnhneVLQhkoZbxAXBGUCFe"
      }

      expect(AuthenticatorMock, :sign_in_client_credentials, fn _input ->
        {:ok, success_payload()}
      end)

      assert %{"access_token" => _, "refresh_token" => _, "token_type" => _, "expires_in" => _} =
               conn
               |> post(@token_endpoint, params)
               |> json_response(200)
    end

    test "fails in Resource Owner Flow if params are invalid", %{conn: conn} do
      expect(AuthenticatorMock, :sign_in_resource_owner, fn input when is_map(input) ->
        ResourceOwner.cast_and_apply(input)
      end)

      assert %{
               "response" => %{
                 "scope" => ["can't be blank"],
                 "client_id" => ["can't be blank"],
                 "client_assertion" => ["can't be blank"],
                 "client_assertion_type" => ["can't be blank"],
                 "password" => ["can't be blank"],
                 "username" => ["can't be blank"]
               }
             } =
               conn
               |> post(@token_endpoint, %{"grant_type" => "password"})
               |> json_response(400)
    end

    test "fails in Refresh Token Flow if params are invalid", %{conn: conn} do
      expect(AuthenticatorMock, :sign_in_refresh_token, fn input when is_map(input) ->
        RefreshToken.cast_and_apply(input)
      end)

      assert %{"response" => %{"refresh_token" => ["can't be blank"]}} =
               conn
               |> post(@token_endpoint, %{"grant_type" => "refresh_token"})
               |> json_response(400)
    end

    test "fails in Client Credentials Flow if params are invalid", %{conn: conn} do
      expect(AuthenticatorMock, :sign_in_client_credentials, fn input when is_map(input) ->
        ClientCredentials.cast_and_apply(input)
      end)

      assert %{
               "response" => %{
                 "scope" => ["can't be blank"],
                 "client_id" => ["can't be blank"],
                 "client_assertion" => ["can't be blank"],
                 "client_assertion_type" => ["can't be blank"]
               }
             } =
               conn
               |> post(@token_endpoint, %{"grant_type" => "client_credentials"})
               |> json_response(400)
    end
  end

  describe "POST #{@logout_endpoint}" do
    setup do
      {:ok, access_token: "my-access-token", claims: default_claims()}
    end

    test "suceeds in if authenticated", %{conn: conn, access_token: access_token, claims: claims} do
      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthenticatorMock, :sign_out_session, fn %{jti: jti} ->
        assert claims["jti"] == jti
        {:ok, %{}}
      end)

      assert conn
             |> put_req_header("authorization", "Bearer #{access_token}")
             |> post(@logout_endpoint)
             |> response(204)
    end

    test "fails if sessions not active", %{conn: conn, access_token: access_token, claims: claims} do
      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthenticatorMock, :sign_out_session, fn %{jti: jti} ->
        assert claims["jti"] == jti
        {:error, :not_active}
      end)

      assert conn
             |> put_req_header("authorization", "Bearer #{access_token}")
             |> post(@logout_endpoint)
             |> response(403)
    end

    test "fails if session not found", %{conn: conn, access_token: access_token, claims: claims} do
      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthenticatorMock, :sign_out_session, fn %{jti: jti} ->
        assert claims["jti"] == jti
        {:error, :not_found}
      end)

      assert conn
             |> put_req_header("authorization", "Bearer #{access_token}")
             |> post(@logout_endpoint)
             |> response(404)
    end
  end

  describe "POST #{@logout_all_endpoint}" do
    test "suceeds in if authenticated", %{conn: conn} do
      access_token = "my-access-token"
      claims = default_claims()

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthenticatorMock, :sign_out_all_sessions, fn subject_id, subject_type ->
        assert claims["sub"] == subject_id
        assert claims["identity"] == subject_type
        {:ok, 3}
      end)

      assert conn
             |> put_req_header("authorization", "Bearer #{access_token}")
             |> post(@logout_all_endpoint)
             |> response(204)
    end

    test "fails if sesions not active", %{conn: conn} do
      access_token = "my-access-token"
      claims = default_claims()

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthenticatorMock, :sign_out_all_sessions, fn subject_id, subject_type ->
        assert claims["sub"] == subject_id
        assert claims["identity"] == subject_type
        {:error, :not_active}
      end)

      assert conn
             |> put_req_header("authorization", "Bearer #{access_token}")
             |> post(@logout_all_endpoint)
             |> response(403)
    end

    test "fails if session not found", %{conn: conn} do
      access_token = "my-access-token"
      claims = default_claims()

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthenticatorMock, :sign_out_all_sessions, fn subject_id, subject_type ->
        assert claims["sub"] == subject_id
        assert claims["identity"] == subject_type
        {:error, :not_found}
      end)

      assert conn
             |> put_req_header("authorization", "Bearer #{access_token}")
             |> post(@logout_all_endpoint)
             |> response(404)
    end
  end

  defp default_claims do
    %{
      "jti" => "03eds74a-c291-4b5f",
      "aud" => "02eff74a-c291-4b5f-a02f-4f92d8daf693",
      "azp" => "my-application",
      "sub" => "272459ce-7356-4460-b461-1ecf0ebf7c4e",
      "typ" => "Bearer",
      "identity" => "user",
      "scope" => "admin:read"
    }
  end

  defp success_session(claims) do
    %{
      id: "02eff44a-c291-4b5f-a02f-4f92d8dbf693",
      jti: claims["jti"],
      subject_id: claims["sub"],
      subject_type: claims["identity"],
      expires_at: claims["expires_at"],
      scopes: parse_scopes(claims["scope"]),
      azp: claims["azp"],
      claims: claims
    }
  end

  defp parse_scopes(scope) when is_binary(scope) do
    scope
    |> String.split(" ", trim: true)
    |> Enum.map(& &1)
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
