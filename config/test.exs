use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :elawesome, ElawesomeWeb.Endpoint,
  http: [port: 7004],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
