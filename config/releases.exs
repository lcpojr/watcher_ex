import Config

config :rest_api, RestAPI.Endpoint,
  url: [host: System.fetch_env!("APP_NAME") <> ".gigalixirapp.com", port: 443],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true
