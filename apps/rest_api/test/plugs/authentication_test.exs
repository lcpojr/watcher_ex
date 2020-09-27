defmodule RestAPI.Plugs.AuthenticationTest do
  use RestAPI.ConnCase, async: true

  alias RestAPI.Plugs.Authentication
  alias RestAPI.Ports.AuthenticatorMock

  describe "#{Authentication}.init/1" do
    test "returns the given conn" do
      assert [] == Authentication.init([])
    end
  end

  describe "#{Authentication}.call/2" do
    test "succeeds and authenticate the session", %{conn: conn} do
      access_token = "my-token"
      claims = default_claims()

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      assert %Plug.Conn{private: %{session: session}} =
               conn
               |> put_req_header("authorization", "Bearer #{access_token}")
               |> Authentication.call([])

      assert claims["jti"] == session.jti
    end

    test "fails if header is invalid", %{conn: conn} do
      assert %Plug.Conn{status: 403} = Authentication.call(conn, [])
    end

    test "fails if token is not bearer invalid", %{conn: conn} do
      assert %Plug.Conn{status: 403} =
               conn
               |> put_req_header("authorization", "my-token")
               |> Authentication.call([])
    end

    test "fails if token is not valid", %{conn: conn} do
      access_token = "my-token"

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:error, :invalid_signature}
      end)

      assert %Plug.Conn{status: 403} =
               conn
               |> put_req_header("authorization", "Bearer #{access_token}")
               |> Authentication.call([])
    end

    test "fails if session not found", %{conn: conn} do
      access_token = "my-token"
      claims = default_claims()

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:error, :not_found}
      end)

      assert %Plug.Conn{status: 403} =
               conn
               |> put_req_header("authorization", "Bearer #{access_token}")
               |> Authentication.call([])
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
