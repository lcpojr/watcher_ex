import Config

# You can change the endpoint configurations the way it suits you better
# This is just for us to have an exemple running on gigalixir
# https://watcherex.gigalixirapp.com/
config :rest_api, RestAPI.Endpoint,
  http: [port: {:system, "PORT"}],
  url: [host: System.fetch_env!("APP_NAME") <> ".gigalixirapp.com", port: 443],
  secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
  server: true
