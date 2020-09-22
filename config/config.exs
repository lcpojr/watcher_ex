import Config

config :admin,
  generators: [context_app: false]

# Configures the endpoint
config :admin, Admin.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "5GgoTrY5c84wVWiKTwovJGWo3gc66GtAe24c6hpFhN/grWsAiICHS5k9izw1HXGE",
  render_errors: [view: Admin.ErrorView, accepts: ~w(html json), layout: false],
  live_view: [signing_salt: "zbl8sDUG"]

config :logger, :console, format: "$metadata[$level] $time $message\n", handle_sasl_reports: true
config :joken, default_signer: "secret"
config :phoenix, :json_library, Jason

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
config :authenticator, Authenticator.Ports.ResourceManager, domain: ResourceManager

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

config :rest_api, RestAPI.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: RestAPI.Views.Errors.Default, accepts: ~w(json), layout: false]

config :rest_api, RestAPI.Application, children: [RestAPI.Telemetry, RestAPI.Endpoint]
config :rest_api, RestAPI.Ports.Authenticator, domain: Authenticator


########
# Admin
########

config :admin, Admin.Endpoint,
  url: [host: "localhost"],
  pubsub_server: Admin.PubSub,
  render_errors: [view: Admin.ErrorView, accepts: ~w(json), layout: false]

config :admin, Admin.Application, children: [Admin.Telemetry, Admin.Endpoint]

import_config "#{Mix.env()}.exs"
