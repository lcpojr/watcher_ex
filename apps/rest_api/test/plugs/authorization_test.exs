defmodule RestAPI.Plugs.AuthorizationTest do
  use RestAPI.ConnCase, async: true

  alias RestAPI.Plugs.Authorization
  alias RestAPI.Ports.AuthorizerMock

  describe "#{Authorization}.init/1" do
    test "returns the given conn" do
      assert [] == Authorization.init([])
    end
  end

  describe "#{Authorization}.call/2" do
    setup do
      claims = default_claims()
      {:ok, session: success_session(claims)}
    end

    test "succeeds and authorizer the subject in public endpoint", ctx do
      conn = %{ctx.conn | private: %{session: ctx.session}}

      expect(AuthorizerMock, :authorize_public, fn _conn -> :ok end)

      assert %Plug.Conn{private: %{session: _}} = Authorization.call(conn, type: "public")
    end

    test "succeeds and authorizer the subject in admin endpoint", ctx do
      conn = %{ctx.conn | private: %{session: ctx.session}}

      expect(AuthorizerMock, :authorize_admin, fn _conn -> :ok end)

      assert %Plug.Conn{private: %{session: _}} = Authorization.call(conn, type: "admin")
    end

    test "succeeds and authorizer the subject as public if option not passed", ctx do
      conn = %{ctx.conn | private: %{session: ctx.session}}
      assert %Plug.Conn{private: %{session: _}} = Authorization.call(conn, [])
    end

    test "fails if session not authenticated", %{conn: conn} do
      assert %Plug.Conn{status: 401} = Authorization.call(conn, type: "admin")
    end

    test "fails if subject unauthorized", ctx do
      conn = %{ctx.conn | private: %{session: ctx.session}}

      expect(AuthorizerMock, :authorize_admin, fn _conn -> {:error, :unauthorized} end)
      expect(AuthorizerMock, :authorize_public, fn _conn -> {:error, :unauthorized} end)

      assert %Plug.Conn{status: 401} = Authorization.call(conn, type: "admin")
      assert %Plug.Conn{status: 401} = Authorization.call(conn, type: "public")
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
