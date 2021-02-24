defmodule RestAPI.Routers.Admin do
  @moduledoc false

  use RestAPI.Router

  alias RestAPI.Plugs.{Authentication, Authorization}

  pipeline :authenticated do
    plug Authentication
  end

  pipeline :authorized_by_admin do
    plug Authorization, type: "admin"
  end

  scope "/v1", RestAPI.Controller.Admin do
    pipe_through :authenticated
    pipe_through :authorized_by_admin

    resources("/users", User, except: [:new])
  end
end
