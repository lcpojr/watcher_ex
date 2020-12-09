defmodule RestAPI.Routers.Public do
  @moduledoc false

  use RestAPI.Router

  alias PhoenixSwagger.Plug.SwaggerUI

  alias RestAPI.Controllers.Public
  alias RestAPI.Plugs.Authentication

  pipeline :rest_api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug Authentication
  end

  # This should be used only for documentation purposes
  # When running in production it should be disabled
  scope "/v1/swagger" do
    forward "/", SwaggerUI, otp_app: :rest_api, swagger_file: "swagger.json"
  end

  scope "/v1", Public do
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
