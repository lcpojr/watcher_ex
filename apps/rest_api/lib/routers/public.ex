defmodule RestAPI.Routers.Public do
  @moduledoc false

  use RestAPI.Router

  alias RestAPI.Controllers.Public
  alias RestAPI.Plugs.{Authentication, Authorization, Tracker}

  pipeline :rest_api do
    plug :accepts, ["json"]
    plug Tracker
  end

  pipeline :authorized_as_user do
    plug Authorization, type: "public"
  end

  pipeline :authenticated do
    plug Authentication
  end

  scope "/v1", Public do
    pipe_through :rest_api

    scope "/auth/protocol/openid-connect" do
      post "/token", Auth, :token

      scope "/authorize" do
        pipe_through :authenticated
        pipe_through :authorized_as_user

        post "/", Auth, :authorize
      end

      scope "/" do
        pipe_through :authenticated

        post "/logout", Auth, :logout
        post "/logout-all-sessions", Auth, :logout_all_sessions
      end
    end
  end
end
