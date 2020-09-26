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

    scope "/auth/protocol/openid-connect" do
      post "/token", Auth, :sign_in

      scope "/" do
        pipe_through :authenticated

        post "/logout", Auth, :sign_out
        post "/logout-all-sessions", Auth, :sign_out_all_sessions
      end
    end
  end
end
