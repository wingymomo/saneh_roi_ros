import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :saneh_roi_ros, SanehRoiRos.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: 5434,
  database: "saneh_roi_ros_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# The server runs during test so Wallaby feature tests can drive a browser.
# Each MIX_TEST_PARTITION gets its own port (4002, 4003, …) so partitioned
# runs on one host do not collide; Wallaby's base_url follows it.
test_partition =
  case System.get_env("MIX_TEST_PARTITION", "") do
    "" -> 0
    partition -> String.to_integer(partition)
  end

config :saneh_roi_ros, SanehRoiRosWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002 + test_partition],
  secret_key_base: "r4CyntvePq68UUb+66Q0yeqwhXVZmmcrazoec9HOaW7zcNbyrmUrTCDQAXIgxqzk",
  server: true

# Share the Ecto sandbox with browser sessions, and mount the UI gallery.
config :saneh_roi_ros, sql_sandbox: true, ui_gallery: true

config :wallaby,
  otp_app: :saneh_roi_ros,
  driver: Wallaby.Chrome,
  screenshot_on_failure: true,
  screenshot_dir: "tmp/wallaby_screenshots",
  chromedriver: [
    headless: System.get_env("WALLABY_HEADLESS", "true") != "false",
    path: System.get_env("CHROMEDRIVER_PATH", "chromedriver")
  ]

# In test we don't send emails
config :saneh_roi_ros, SanehRoiRos.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
