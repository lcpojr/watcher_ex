defmodule RestApiWeb.Router do
  use RestApiWeb, :router

  pipeline :rest_api do
    plug :accepts, ["json"]
  end

  scope "/api", RestApiWeb do
    pipe_through :rest_api
  end
end
