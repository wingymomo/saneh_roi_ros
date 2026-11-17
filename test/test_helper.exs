# Browser (Wallaby) tests are tagged :feature. They need Chrome and a
# matching chromedriver on PATH (`mise install`, see mise.toml, or
# CHROMEDRIVER_PATH); without them they are skipped instead of failing
# the whole suite.
exclude =
  case Application.ensure_all_started(:wallaby) do
    {:ok, _} ->
      Application.put_env(:wallaby, :base_url, SanehRoiRosWeb.Endpoint.url())
      []

    {:error, _reason} ->
      IO.puts(:stderr, """
      [wallaby] could not start: no chromedriver matching your Chrome on PATH
      (run `mise install`, or set CHROMEDRIVER_PATH) — skipping :feature tests
      """)

      [:feature]
  end

ExUnit.start(exclude: exclude)
Ecto.Adapters.SQL.Sandbox.mode(SanehRoiRos.Repo, :manual)
