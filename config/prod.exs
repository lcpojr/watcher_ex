use Mix.Config

config :logger, level: :info

##########
# Rest API
##########

# ALL CONFIGURATIONS HERE SHOULD CHANGE IN THE FUTURE
# THIS IS JUST FOR TEST PURPOSES

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :rest_api, RestAPI.Endpoint,
  url: [host: "example.com", port: 80],
  cache_static_manifest: "priv/static/cache_manifest.json",
  url: [host: "example.com", port: 443],
  secret_key_base: System.fetch_env("SECRET_KEY_BASE"),
  force_ssl: [hsts: true],
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: System.fetch_env("SSL_KEY_PATH"),
    certfile: System.fetch_env("SSL_CERT_PATH"),
    transport_options: [socket_opts: [:inet6]]
  ]
