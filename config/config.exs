# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.

import Config

config :joken, default_signer: "secret"

###################
# RESOURCE MANAGER
###################

config :resource_manager, ecto_repos: [ResourceManager.Repo]

config :resource_manager, ResourceManager.Repo,
  database: "resource_manager_#{Mix.env()}",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5432

################
# AUTHENTICATOR
################

config :authenticator, Authenticator.Authentication.Ports.GetIdentity,
  command: ResourceManager.Identity.Commands.GetIdentity

import_config "#{Mix.env()}.exs"
