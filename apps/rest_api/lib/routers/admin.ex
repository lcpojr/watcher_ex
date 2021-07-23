defmodule RestAPI.Routers.Admin do
  @moduledoc false

  use RestAPI.Router

  alias RestAPI.Plugs.{Authentication, Authorization, Tracker}

  pipeline :authenticated do
    plug Authentication
    plug Tracker
  end

  pipeline :authorized do
    plug Authorization, type: "admin"
  end

  scope "/v1", RestAPI.Controllers.Admin do
    pipe_through :authenticated
    pipe_through :authorized

    resources "/users", Users, except: [:new]

    scope "/sessions" do
      post "/logout", Sessions, :logout
      post "/logout-all-sessions", Sessions, :logout_all_sessions
    end
  end
end
