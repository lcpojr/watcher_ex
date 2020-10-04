defmodule RestAPI.Controller.Admin.User do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias RestAPI.Ports.{Authenticator, ResourceManager}
  alias RestAPI.Views.Admin.User

  action_fallback RestAPI.Controllers.Fallback

  def create(conn, %{"password" => password} = params) do
    password_hash = Authenticator.generate_hash(password, :argon2)

    params
    |> Map.put("password_hash", password_hash)
    |> Map.put("password_algorithm", "argon2")
    |> ResourceManager.create_identity()
    |> case do
      {:ok, response} ->
        conn
        |> put_status(:created)
        |> put_view(User)
        |> render("create.json", response: response)

      {:error, _any} = error ->
        error
    end
  end
end
