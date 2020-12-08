defmodule RestAPI.Controllers.Admin.User do
  use RestAPI.ConnCase, async: true

  alias ResourceManager.Identities.Commands.Inputs.CreateUser
  alias RestAPI.Ports.{AuthenticatorMock, AuthorizerMock, ResourceManagerMock}

  @create_endpoint "/admin/v1/users"
  @show_endpoint "/admin/v1/users/"

  describe "POST #{@create_endpoint}" do
    setup do
      access_token = "my-access-token"
      claims = default_claims()

      {:ok, access_token: access_token, claims: claims}
    end

    test "should render user identity response", %{
      conn: conn,
      access_token: access_token,
      claims: claims
    } do
      password = "MyP@ssword1234"

      params = %{
        "username" => "Shurato",
        "password" => password,
        "scopes" => [
          "6a3a3771-9f56-4254-9497-927e441dacfc",
          "8a235ba0-a827-4593-92c9-6248bef4fa06"
        ]
      }

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(ResourceManagerMock, :password_allowed?, fn _input ->
        true
      end)

      expect(AuthenticatorMock, :generate_hash, fn password_to_hash, :argon2 ->
        assert password == password_to_hash
        "password_hashed"
      end)

      expect(ResourceManagerMock, :create_identity, fn input ->
        assert is_map(input)

        {:ok,
         %{
           id: Ecto.UUID.generate(),
           inserted_at: NaiveDateTime.utc_now(),
           is_admin: false,
           status: "active",
           updated_at: NaiveDateTime.utc_now(),
           username: "Shurato"
         }}
      end)

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

      assert %{
               "id" => _id,
               "inserted_at" => _inserted_at,
               "is_admin" => false,
               "status" => "active",
               "username" => "Shurato"
             } =
               conn
               |> put_req_header("authorization", "Bearer #{access_token}")
               |> post(@create_endpoint, params)
               |> json_response(201)
    end

    test "should return error when params is not valid", %{
      conn: conn,
      access_token: access_token,
      claims: claims
    } do
      password = "MyP@ssword"

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(ResourceManagerMock, :password_allowed?, fn _input ->
        true
      end)

      expect(AuthenticatorMock, :generate_hash, fn password_to_hash, :argon2 ->
        assert password == password_to_hash
        "password_hashed"
      end)

      expect(ResourceManagerMock, :create_identity, fn input ->
        CreateUser.cast_and_apply(input)
      end)

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

      assert %{
               "detail" => "The given params failed in validation",
               "error" => "bad_request",
               "response" => %{"username" => ["can't be blank"]},
               "status" => 400
             } =
               conn
               |> put_req_header("authorization", "Bearer #{access_token}")
               |> post(@create_endpoint, %{"password" => password})
               |> json_response(400)
    end

    test "should return error when password is not strong enough", %{
      conn: conn,
      access_token: access_token,
      claims: claims
    } do
      password = "MyP@ssword"

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthenticatorMock, :sign_out_session, fn jti ->
        assert claims["jti"] == jti
        {:ok, %{}}
      end)

      expect(ResourceManagerMock, :password_allowed?, fn _input ->
        false
      end)

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

      assert %{
               "detail" => "The given params failed in validation",
               "error" => "bad_request",
               "response" => %{"password" => ["password is not strong enough"]},
               "status" => 400
             } ==
               conn
               |> put_req_header("authorization", "Bearer #{access_token}")
               |> post(@create_endpoint, %{"password" => password})
               |> json_response(400)
    end
  end

  describe "GET #{@show_endpoint}" do
    setup do
      access_token = "my-access-token"
      claims = default_claims()

      {:ok, access_token: access_token, claims: claims, user: insert!(:user)}
    end

    test "should render user identity", %{
      conn: conn,
      access_token: access_token,
      claims: claims,
      user: user
    } do
      username = user.username

      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

      expect(ResourceManagerMock, :get_identity, fn input ->
        assert is_map(input)

        {:ok,
         %{
           id: user.id,
           inserted_at: NaiveDateTime.utc_now(),
           is_admin: user.is_admin,
           status: user.status,
           updated_at: NaiveDateTime.utc_now(),
           username: username
         }}
      end)

      assert %{
               "id" => _id,
               "inserted_at" => _inserted_at,
               "updated_at" => _updated_at,
               "is_admin" => false,
               "status" => "active",
               "username" => ^username
             } =
               conn
               |> put_req_header("authorization", "Bearer #{access_token}")
               |> get(@show_endpoint <> "username")
               |> json_response(201)
    end

    test "if id is not an id, should return error", %{
      conn: conn,
      access_token: access_token,
      claims: claims
    } do
      expect(AuthenticatorMock, :validate_access_token, fn token ->
        assert access_token == token
        {:ok, claims}
      end)

      expect(AuthenticatorMock, :get_session, fn %{"jti" => jti} ->
        assert claims["jti"] == jti
        {:ok, success_session(claims)}
      end)

      expect(AuthorizerMock, :authorize_admin, fn %Plug.Conn{} -> :ok end)

      expect(ResourceManagerMock, :get_identity, fn input ->
        assert is_map(input)

        {:error, {:error, :invalid_params}}
      end)

      assert %{
               "detail" => "The given parameters are invalid",
               "error" => "bad_request",
               "status" => 400
             } =
               conn
               |> put_req_header("authorization", "Bearer #{access_token}")
               |> get(@show_endpoint <> "1")
               |> json_response(400)
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
