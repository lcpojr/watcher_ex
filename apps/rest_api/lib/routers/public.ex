defmodule RestApi.Routers.Public do
  use RestApi.Router

  pipeline :rest_api do
    plug :accepts, ["json"]
  end

  scope "/api/v1", RestApi.Controllers do
    pipe_through :rest_api

    post "/auth/protocol/openid-connect/token", Token, :sign_in
  end
end
