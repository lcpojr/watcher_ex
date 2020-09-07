use Mix.Config

config :logger, level: :error

###################
# RESOURCE MANAGER
###################

config :resource_manager, ResourceManager.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :resource_manager, ResourceManager.Credentials.Ports.HashSecret,
  command: ResourceManager.Credentials.Ports.HashSecretMock
