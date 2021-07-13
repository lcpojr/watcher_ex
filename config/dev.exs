import Config

###################
# Resource Manager
###################

config :resource_manager, ResourceManager.Repo, show_sensitive_data_on_connection_error: true

################
# Authenticator
################

config :authenticator, Authenticator.Repo, show_sensitive_data_on_connection_error: true

##########
# Rest API
##########

config :rest_api, RestAPI.Endpoint,
  http: [port: 4000],
  https: [
    port: 4001,
    cipher_suite: :strong,
    certfile: "priv/cert/selfsigned.pem",
    keyfile: "priv/cert/selfsigned_key.pem"
  ],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, level: :debug
