defmodule RestAPI.Routers.Public do
  @moduledoc false

  use RestAPI.Router

  alias RestAPI.Plugs.Authentication

  pipeline :rest_api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug Authentication
  end

  scope "/api/v1", RestAPI.Controllers.Public do
    pipe_through :rest_api

    post "/auth/protocol/openid-connect/token", Tokens, :sign_in

    scope "/sessions" do
      pipe_through :authenticated

      post "/logout", Sessions, :logout
    end
  end
end
