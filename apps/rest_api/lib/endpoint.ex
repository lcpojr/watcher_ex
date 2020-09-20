defmodule RestApi.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :rest_api

  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # Routers
  plug RestApi.Routers.Public
end
