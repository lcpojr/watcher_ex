import Config

config :logger, level: :info

###################
# Resource Manager
###################

config :resource_manager, ResourceManager.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: System.fetch_env!("DATABASE_POOL_SIZE")

################
# Authenticator
################

config :authenticator, Authenticator.Repo,
  url: System.fetch_env!("DATABASE_URL"),
  pool_size: System.fetch_env!("DATABASE_POOL_SIZE")
