defmodule RestAPI.Controllers.FallbackTest do
  use RestAPI.ConnCase, async: true

  alias ResourceManager.Identities.Commands.Inputs.CreateUser
  alias RestAPI.Controllers.Fallback

  test "handles bad request responses", %{conn: conn} do
    assert %{
             "detail" => "The given parameters are invalid",
             "error" => "bad_request",
             "status" => 400
           } ==
             conn
             |> Fallback.call({:error, :invalid_params})
             |> json_response(400)
  end

  test "handles unathorized responses", %{conn: conn} do
    assert %{
             "detail" => "Not authorized to perform such action",
             "error" => "unauthorized",
             "status" => 401
           } ==
             conn
             |> Fallback.call({:error, :unauthorized})
             |> json_response(401)
  end

  test "handles anauthenticated responses", %{conn: conn} do
    assert %{
             "detail" => "Not authenticated so cannot due such action",
             "error" => "unauthenticated",
             "status" => 403
           } ==
             conn
             |> Fallback.call({:error, :unauthenticated})
             |> json_response(403)
  end

  test "handles not found responses", %{conn: conn} do
    assert %{
             "detail" => "Endpoint not found",
             "error" => "not_found",
             "status" => 404
           } ==
             conn
             |> Fallback.call({:error, :not_found})
             |> json_response(404)
  end

  test "handles changeset responses", %{conn: conn} do
    assert %{
             "detail" => "The given params are invalid",
             "status" => 400,
             "error" => "bad_request",
             "response" => %{
               "password_hash" => ["can't be blank"],
               "username" => ["can't be blank"]
             }
           } ==
             conn
             |> Fallback.call(CreateUser.cast_and_apply(%{}))
             |> json_response(400)
  end

  test "handles unknow responses", %{conn: conn} do
    assert %{
             "detail" => "Internal Server Error",
             "error" => "internal_server_error",
             "status" => 500
           } ==
             conn
             |> Fallback.call({:error, :internal_server_error})
             |> json_response(500)
  end
end
