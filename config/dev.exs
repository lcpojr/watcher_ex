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

config :rest_api, RestAPI.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  watchers: []

########
# Admin
########

config :admin, Admin.Endpoint,
  http: [port: 4001],
  debug_errors: true,
  code_reloader: true,
  check_origin: false,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/(live|views)/.*(ex)$",
      ~r"lib/templates/.*(eex)$"
    ]
  ],
  watchers: [
    node: [
      "node_modules/webpack/bin/webpack.js",
      "--mode",
      "development",
      "--watch-stdin",
      cd: Path.expand("../apps/admin/assets", __DIR__)
    ]
  ]

config :logger, level: :debug
