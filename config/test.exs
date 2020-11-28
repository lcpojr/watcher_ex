import Config

config :logger, level: :warn
config :ex_unit, capture_log: true
config :argon2_elixir, t_cost: 1, m_cost: 8
config :bcrypt_elixir, log_rounds: 1
config :pbkdf2_elixir, rounds: 1

###################
# RESOURCE MANAGER
###################

config :resource_manager, ResourceManager.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true

config :resource_manager, ResourceManager.Application,
  children: [ResourceManager.Repo, ResourceManager.Credentials.BlocklistPasswordCache]

config :resource_manager, ResourceManager.Ports.Authenticator,
  command: ResourceManager.Ports.AuthenticatorMock

################
# Authenticator
################

config :authenticator, Authenticator.Application, children: [Authenticator.Sessions.Cache]

config :authenticator, Authenticator.Ports.ResourceManager,
  domain: Authenticator.Ports.ResourceManagerMock

config :authenticator, Authenticator.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  show_sensitive_data_on_connection_error: true

#############
# Authorizer
#############

config :authorizer, Authorizer.Ports.ResourceManager, domain: Authorizer.Ports.ResourceManagerMock

##########
# Rest API
##########

config :rest_api, RestAPI.Endpoint,
  http: [port: 4002],
  server: false

config :rest_api, RestAPI.Ports.Authenticator, domain: RestAPI.Ports.AuthenticatorMock
config :rest_api, RestAPI.Ports.Authorizer, domain: RestAPI.Ports.AuthorizerMock
config :rest_api, RestAPI.Ports.ResourceManager, domain: RestAPI.Ports.ResourceManagerMock
