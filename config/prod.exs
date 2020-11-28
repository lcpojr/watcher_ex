import Config

config :logger, level: :info

###################
# Resource Manager
###################

config :resource_manager, ResourceManager.Repo, url: System.fetch_env!("DATABASE_URL")

################
# Authenticator
################

config :authenticator, Authenticator.Repo, url: System.fetch_env!("DATABASE_URL")
