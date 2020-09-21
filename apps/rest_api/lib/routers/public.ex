defmodule RestAPI.Routers.Public do
  @moduledoc false

  use RestAPI.Router

  pipeline :rest_api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", RestAPI.Controllers do
    pipe_through :rest_api

    post "/auth/protocol/openid-connect/token", Token, :sign_in
  end
end
