defmodule RestAPI.Routers.Admin do
  @moduledoc false

  use RestAPI.Router

  alias RestAPI.Plugs.{Authentication, Authorization, Tracker}

  pipeline :authenticated do
    plug Authentication
    plug Tracker
  end

  pipeline :authorized_as_admin do
    plug Authorization, type: "admin"
  end

  scope "/v1", RestAPI.Controllers.Admin do
    pipe_through :authenticated
    pipe_through :authorized_as_admin

    resources "/users", Users, except: [:new]
  end
end
