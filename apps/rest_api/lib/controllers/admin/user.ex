defmodule RestAPI.Controller.Admin.User do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias ResourceManager.Identities.Commands.Inputs.CreateUser
  alias RestAPI.Ports.ResourceManager
  alias RestAPI.Views.Admin.User

  action_fallback RestAPI.Controllers.Fallback

  @doc "Creates a new user identity"
  @spec create(conn :: Plug.Conn.t(), params :: map()) :: Plug.Conn.t()
  def create(conn, params) do
    with {:ok, input} <- CreateUser.cast_and_apply(params),
         {:ok, response} <- ResourceManager.create_user(input) do
      conn
      |> put_status(201)
      |> put_view(User)
      |> render("create.json", response: response)
    end
  end
end
