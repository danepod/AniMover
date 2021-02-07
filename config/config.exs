# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :ani_mover, AniMoverWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "wWLvrVTVH61BrDYnV1vGsNddhsTE3QIUI1v5ICkC/0bBUAH0MNKSh0FCkfyCLp9O",
  render_errors: [view: AniMoverWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: AniMover.PubSub,
  live_view: [signing_salt: "zP3rDZnx"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
