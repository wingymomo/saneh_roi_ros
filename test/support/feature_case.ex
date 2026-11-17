defmodule SanehRoiRosWeb.FeatureCase do
  @moduledoc """
  Case for browser tests driven by Wallaby (Chrome + chromedriver).

  Tests using it are tagged `:feature`; they are skipped automatically when
  chromedriver is not available (see `test/test_helper.exs`).
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      import Wallaby.Query
      import SanehRoiRosWeb.FeatureCase

      @moduletag :feature
    end
  end

  @doc "Runs `script` in the browser and returns its result."
  def eval_js(session, script, args \\ []) do
    ref = make_ref()
    Wallaby.Browser.execute_script(session, script, args, &send(self(), {ref, &1}))

    receive do
      {^ref, value} -> value
    after
      5_000 -> flunk("script did not return: #{script}")
    end
  end

  @doc """
  Scrolls `selector` to the middle of the viewport, then clicks it.

  Plain `click/2` may scroll the target just under the sticky category tabs,
  so the click lands on the tabs instead.
  """
  def click_centered(session, selector) do
    eval_js(
      session,
      ~s|document.querySelector(arguments[0]).scrollIntoView({block: "center"}); return true|,
      [selector]
    )

    Wallaby.Browser.click(session, Wallaby.Query.css(selector))
  end

  @doc "Reads a computed CSS property of the first element matching `selector`."
  def computed_style(session, selector, property) do
    eval_js(
      session,
      """
      const el = document.querySelector(arguments[0]);
      return el ? getComputedStyle(el).getPropertyValue(arguments[1]) : null;
      """,
      [selector, property]
    )
  end

  @doc "Polls `fun` until it returns a truthy value (or fails after `timeout` ms)."
  def eventually(fun, timeout \\ 3_000, interval \\ 50) do
    deadline = System.monotonic_time(:millisecond) + timeout
    do_eventually(fun, deadline, interval)
  end

  defp do_eventually(fun, deadline, interval) do
    case fun.() do
      result when result not in [nil, false] ->
        result

      _ ->
        if System.monotonic_time(:millisecond) > deadline do
          flunk("condition was not met in time")
        else
          Process.sleep(interval)
          do_eventually(fun, deadline, interval)
        end
    end
  end
end
