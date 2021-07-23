defmodule RestAPI.Controllers.Admin.SessionsTest do
  @moduledoc false

  use RestAPI.ConnCase, async: true

  alias RestAPI.Ports.{AuthenticatorMock, AuthorizerMock}

  @logout_endpoint "/admin/v1/sessions/logout"
  @logout_all_endpoint "/admin/v1/sessions/logout-all-sessions"

  describe "POST #{@logout_endpoint}" do
    setup do
      {:ok, access_token: "my-access-token", claims: default_claims()}
    end

    test "suceeds if token is valid", %{conn: conn, access_token: access_token, claims: claims} do
      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

      expect(AuthenticatorMock, :sign_out_session, fn jti ->
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

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

      expect(AuthenticatorMock, :sign_out_session, fn jti ->
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

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

      expect(AuthenticatorMock, :sign_out_session, fn jti ->
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

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

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

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

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

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

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
end
