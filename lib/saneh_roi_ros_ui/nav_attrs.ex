defmodule SanehRoiRosUI.NavAttrs do
  @moduledoc """
  Decides whether a component's `rest` attributes make it a link.

  A control is a link only when it has `href`, `navigate` or `patch` **and**
  is not `disabled`: an `<a>` ignores `disabled`, so a disabled control is
  rendered in its non-link form with the navigation attributes removed.
  """

  @nav_keys [:href, :navigate, :patch, :replace, :method]

  @doc "True when `rest` has a navigation target and is not disabled."
  def link?(rest), do: not disabled?(rest) and Enum.any?([:href, :navigate, :patch], &rest[&1])

  @doc "True when `rest` sets `disabled` to anything but `nil`/`false`."
  def disabled?(rest), do: rest[:disabled] not in [nil, false]

  @doc "`rest` without the navigation attributes."
  def drop_nav(rest), do: Map.drop(rest, @nav_keys)

  @doc """
  Returns `{link?, rest}`: when it is not a link, `rest` comes back without
  the navigation attributes so they never end up on a `<button>`/`<div>`.
  """
  def split(rest) do
    if link?(rest), do: {true, rest}, else: {false, drop_nav(rest)}
  end
end
