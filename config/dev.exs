use Mix.Config

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
  port: 5432

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
  port: 5432

##########
# Rest API
##########

config :rest_api, RestApi.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, level: :debug
