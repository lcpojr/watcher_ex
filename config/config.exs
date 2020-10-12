import Config

config :logger, :console, format: "$metadata[$level] $time $message\n", handle_sasl_reports: true
config :phoenix, :json_library, Jason

# This is just for test purposes and should change in near future
config :joken, default_signer: "secret"

###################
# RESOURCE MANAGER
###################

config :resource_manager, ecto_repos: [ResourceManager.Repo]

config :resource_manager, ResourceManager.Application,
  children: [
    ResourceManager.Repo,
    ResourceManager.Credentials.BlocklistPasswordCache,
    ResourceManager.Credentials.BlocklistPasswordManager,
    ResourceManager.Identities.Manager
  ]

config :resource_manager, ResourceManager.Repo,
  database: "watcher_ex_#{Mix.env()}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432,
  pool_size: 10

config :resource_manager, ResourceManager.Ports.Authenticator, command: Authenticator

################
# Authenticator
################

config :authenticator, ecto_repos: [Authenticator.Repo]
config :authenticator, Authenticator.Ports.ResourceManager, domain: ResourceManager
config :authenticator, Authenticator.Sessions.Cache, n_shards: 2, gc_interval: 3600

config :authenticator, Authenticator.Application,
  children: [
    Authenticator.Repo,
    Authenticator.Sessions.Cache,
    Authenticator.Sessions.Manager
  ]

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

import_config "#{Mix.env()}.exs"
