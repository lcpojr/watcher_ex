defmodule RestAPI.Routers.Documentation do
  @moduledoc false

  use RestAPI.Router

  alias PhoenixSwagger.Plug.SwaggerUI

  # This should be used only for documentation purposes
  # When running in production it should be disabled
  scope "/api/v1/swagger" do
    forward "/", SwaggerUI, otp_app: :rest_api, swagger_file: "swagger.json"
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
