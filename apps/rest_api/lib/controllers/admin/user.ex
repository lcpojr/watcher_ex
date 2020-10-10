defmodule RestAPI.Controller.Admin.User do
  @moduledoc false

  use RestAPI.Controller, :controller

  alias RestAPI.Ports.{Authenticator, ResourceManager}
  alias RestAPI.Views.Admin.User

  action_fallback RestAPI.Controllers.Fallback

  def create(conn, %{"password" => password} = params) do
    with true <- ResourceManager.is_strong?(password),
         password_hash <- Authenticator.generate_hash(password, :argon2),
         params <-
           Map.merge(params, %{"password_hash" => password_hash, "password_algorithm" => "argon2"}),
         {:ok, response} <- ResourceManager.create_identity(params) do
      conn
      |> put_status(:created)
      |> put_view(User)
      |> render("create.json", response: response)
    else
      false ->
        {:error, 422, %{error: :not_strong_enough, password: password}}

      {:error, _any} = error ->
        error
    end
  end
end
