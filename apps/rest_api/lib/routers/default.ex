defmodule RestAPI.Routers.Default do
  @moduledoc false

  use RestAPI.Router

  alias PhoenixSwagger.Plug.SwaggerUI

  alias RestAPI.Controllers.Public
  alias RestAPI.Plugs.{Authentication, Authorization}

  pipeline :rest_api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug Authentication
  end

  pipeline :authorized_by_admin do
    plug Authorization, type: "admin"
  end

  # This should be used only for documentation purposes
  # When running in production it should be disabled
  scope "/api/swagger" do
    forward "/", SwaggerUI, otp_app: :rest_api, swagger_file: "swagger.json"
  end

  scope "/api/v1", Public do
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

  scope "/admin/v1", RestAPI.Controller.Admin do
    pipe_through :authenticated
    pipe_through :authorized_by_admin

    resources("/users", User, except: [:new])
  end

  def swagger_info do
    %{
      schemes: ["https", "http"],
      info: %{
        version: "1.0",
        title: "WatcherEx",
        description: "An Oauth2 and Resource server interelly in elixir.",
        termsOfService: "Open for public",
        contact: %{
          name: "Luiz Carlos",
          email: "lcpojr@gmail.com"
        }
      },
      securityDefinitions: %{
        Bearer: %{
          type: "apiKey",
          name: "Authorization",
          description: "API Token must be provided via `Authorization: Bearer ` header",
          in: "header"
        }
      },
      consumes: ["application/json"],
      produces: ["application/json"],
      tags: []
    }
  end
end
