use Mix.Config

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
