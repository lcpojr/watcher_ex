import Config

config :logger, level: :info

###################
# Resource Manager
###################

config :resource_manager, ResourceManager.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: "DATABASE_POOL_SIZE" |> System.fetch_env!() |> String.to_integer()

################
# Authenticator
################

config :authenticator, Authenticator.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: "DATABASE_POOL_SIZE" |> System.fetch_env!() |> String.to_integer()
