use Mix.Config

config :logger, level: :warn
config :ex_unit, capture_log: true

# Reducing rounds and time cost for crypto
# This should be used only in tests
config :argon2_elixir, t_cost: 1, m_cost: 8
config :bcrypt_elixir, log_rounds: 1
config :pbkdf2_elixir, rounds: 1

###################
# RESOURCE MANAGER
###################

config :resource_manager, ResourceManager.Repo, pool: Ecto.Adapters.SQL.Sandbox

config :resource_manager, ResourceManager.Credentials.Ports.GenerateHash,
  command: ResourceManager.Credentials.Ports.GenerateHashMock

config :resource_manager, ResourceManager.Credentials.Ports.VerifyHash,
  command: ResourceManager.Credentials.Ports.VerifyHashMock

config :resource_manager, ResourceManager.Credentials.Ports.FakeVerifyHash,
  command: ResourceManager.Credentials.Ports.FakeVerifyHashMock

################
# Authenticator
################

config :authenticator, Authenticator.Application, children: [Authenticator.Repo]
config :authenticator, Authenticator.Repo, pool: Ecto.Adapters.SQL.Sandbox

##########
# Rest API
##########

config :rest_api, RestApi.Endpoint,
  http: [port: 4002],
  server: false
