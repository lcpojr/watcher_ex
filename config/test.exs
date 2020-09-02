use Mix.Config

config :logger, level: :error

config :resource_manager, ResourceManager.Repo, pool: Ecto.Adapters.SQL.Sandbox
