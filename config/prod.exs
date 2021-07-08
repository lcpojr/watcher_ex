import Config

config :logger, level: :info

###################
# Resource Manager
###################

config :resource_manager, ResourceManager.Repo,
  database: System.fetch_env!("DATABASE_NAME"),
  username: System.fetch_env!("DATABASE_USERNAME"),
  password: System.fetch_env!("DATABASE_PASSWORD"),
  hostname: System.fetch_env!("DATABASE_HOSTNAME"),
  port: System.fetch_env!("DATABASE_PORT"),
  pool_size: String.to_integer(System.fetch_env!("DATABASE_POOL_SIZE"))

################
# Authenticator
################

config :authenticator, Authenticator.Repo,
  database: System.fetch_env!("DATABASE_NAME"),
  username: System.fetch_env!("DATABASE_USERNAME"),
  password: System.fetch_env!("DATABASE_PASSWORD"),
  hostname: System.fetch_env!("DATABASE_HOSTNAME"),
  port: System.fetch_env!("DATABASE_PORT"),
  pool_size: String.to_integer(System.fetch_env!("DATABASE_POOL_SIZE"))

##########
# Rest API
##########

config :rest_api, RestAPI.Endpoint,
  https: [
    port: 4001,
    cipher_suite: :strong,
    certfile: System.fetch_env!("TLS_CERT_FILE"),
    keyfile: System.fetch_env!("TLS_KEY_FILE")
  ],
  force_ssl: [hsts: true]
