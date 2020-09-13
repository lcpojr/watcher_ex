use Mix.Config

config :logger, level: :warn

###################
# RESOURCE MANAGER
###################

config :resource_manager, ResourceManager.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :resource_manager, ResourceManager.Credentials.Ports.GenerateHash,
  command: ResourceManager.Credentials.Ports.GenerateHashMock

config :resource_manager, ResourceManager.Credentials.Ports.VerifyHash,
  command: ResourceManager.Credentials.Ports.VerifyHashMock

################
# Authenticator
################

config :authenticator, Authenticator.Repo, pool: Ecto.Adapters.SQL.Sandbox
