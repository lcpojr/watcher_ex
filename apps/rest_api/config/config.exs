# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :rest_api, RestApiWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "1uXAyEdFVU9DOL7m1tWnfZdHBzautmZZfKlV7g9aRb4sewAniN4+Jqa2MEzflUZG",
  render_errors: [view: RestApiWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: RestApi.PubSub,
  live_view: [signing_salt: "JiImjGD8"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
