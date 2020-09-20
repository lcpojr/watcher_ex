import Config

config :logger, :console, format: "$metadata[$level] $time $message\n", handle_sasl_reports: true

# This is temporary and will change in the future
# We don't want to expose the secret on configurations
config :joken, default_signer: "secret"

###################
# RESOURCE MANAGER
###################

config :resource_manager, ecto_repos: [ResourceManager.Repo]

config :resource_manager, ResourceManager.Application, children: [ResourceManager.Repo]

config :resource_manager, ResourceManager.Repo,
  database: "watcher_ex_#{Mix.env()}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10

config :resource_manager, ResourceManager.Credentials.Ports.GenerateHash,
  command: Authenticator.Crypto.Commands.GenerateHash

config :resource_manager, ResourceManager.Credentials.Ports.VerifyHash,
  command: Authenticator.Crypto.Commands.VerifyHash

config :resource_manager, ResourceManager.Credentials.Ports.FakeVerifyHash,
  command: Authenticator.Crypto.Commands.FakeVerifyHash

################
# Authenticator
################

config :authenticator, ecto_repos: [Authenticator.Repo]

config :authenticator, Authenticator.Application,
  children: [Authenticator.Repo, Authenticator.Sessions.Manager]

config :authenticator, Authenticator.Repo,
  database: "watcher_ex_#{Mix.env()}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10

##########
# Rest API
##########

config :rest_api, RestApi.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: RestApi.ErrorView, accepts: ~w(json), layout: false]

config :rest_api, RestApi.Application, children: [RestApi.Telemetry, RestApi.Endpoint]

config :phoenix, :json_library, Jason

import_config "#{Mix.env()}.exs"
