defmodule RestAPI.Controllers.Admin.User do
  use RestAPI.ConnCase, async: true

  alias RestAPI.Ports.{AuthenticatorMock, ResourceManagerMock}
  alias ResourceManager.Identity.Commands.Inputs.CreateUser

  @create_endpoint "/admin/v1/users"

  describe "POST #{@create_endpoint}" do
    test "should render user identity response", %{conn: conn} do
      password = "MyP@ssword"

      params = %{
        "username" => "Shurato",
        "password" => password,
        "scopes" => [
          "6a3a3771-9f56-4254-9497-927e441dacfc",
          "8a235ba0-a827-4593-92c9-6248bef4fa06"
        ]
      }

      expect(AuthenticatorMock, :generate_hash, fn password_to_hash, :argon2 ->
        assert password = password_to_hash
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

      assert %{
               "id" => _id,
               "inserted_at" => _inserted_at,
               "is_admin" => false,
               "status" => "active",
               "username" => "Shurato"
             } =
               conn
               |> post(@create_endpoint, params)
               |> json_response(201)
    end

    test "should return error when params is not valid", %{conn: conn} do
      password = "MyP@ssword"

      expect(AuthenticatorMock, :generate_hash, fn password_to_hash, :argon2 ->
        assert password = password_to_hash
        "password_hashed"
      end)

      expect(ResourceManagerMock, :create_identity, fn input ->
        CreateUser.cast_and_apply(input)
      end)

      assert %{
               "detail" => "The given params are invalid",
               "error" => "bad_request",
               "response" => %{"username" => ["can't be blank"]},
               "status" => 400
             } =
               conn
               |> post(@create_endpoint, %{"password" => password})
               |> json_response(400)
    end

    test "should return error when password is not strong enough", %{conn: conn} do
      password = "MyP@ssword"

      expect(ResourceManagerMock, :is_strong?, fn _input ->
        false
      end)

      assert %{
               "detail" => "The given params failed in validation",
               "error" => "unprocessable entity",
               "response" => %{"error" => "not_strong_enough", "password" => "MyP@ssword"},
               "status" => 422
             } =
               conn
               |> post(@create_endpoint, %{"password" => password})
               |> json_response(422)
    end
  end
end
