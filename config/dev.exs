use Mix.Config

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

config :rest_api, RestApi.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :logger, level: :debug
