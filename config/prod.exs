use Mix.Config

config :logger, level: :info

###########
# Rest API
###########

# ALL CONFIGURATIONS HERE SHOULD CHANGE IN THE FUTURE
# THIS IS JUST FOR TEST PURPOSES

config :rest_api, RestAPI.Endpoint,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.fetch_env("SECRET_KEY_BASE"),
  force_ssl: [hsts: true],
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: System.fetch_env("SSL_KEY_PATH"),
    certfile: System.fetch_env("SSL_CERT_PATH"),
    transport_options: [socket_opts: [:inet6]]
  ]

########
# Admin
########

# ALL CONFIGURATIONS HERE SHOULD CHANGE IN THE FUTURE
# THIS IS JUST FOR TEST PURPOSES

config :admin, Admin.Endpoint,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  secret_key_base: System.fetch_env("SECRET_KEY_BASE"),
  force_ssl: [hsts: true],
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: System.fetch_env("SSL_KEY_PATH"),
    certfile: System.fetch_env("SSL_CERT_PATH"),
    transport_options: [socket_opts: [:inet6]]
  ]
