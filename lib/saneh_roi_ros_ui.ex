defmodule SanehRoiRosUI do
  @moduledoc """
  UI kit of the เสน่ห์ร้อยรส staff app (mobile, portrait, Thai UI).

  Every component is a stateless `Phoenix.Component`; LiveViews own the state
  and handle `phx-click` events. Only `toast/1` ships JavaScript (a colocated
  hook).

  Some component names (`button`, `input`, `list`, `icon`) also exist in the
  generated core components, so call the kit through an alias instead of
  importing it:

      use SanehRoiRosUI   # alias SanehRoiRosUI, as: UI

      <UI.button variant={:primary}>เสร็จ · 60</UI.button>

  Implementations live in `SanehRoiRosUI.*` modules, which can also be
  imported directly when there is no name clash.
  """

  alias SanehRoiRosUI.{Badges, Buttons, Controls, Form, Icon, Layout, Navigation}

  defmacro __using__(_opts) do
    quote do
      alias SanehRoiRosUI, as: UI
    end
  end

  @doc """
  Formats an integer price the way the UI shows it: whole baht, thousands
  separator, the word "บาท", no ฿ symbol.

      iex> SanehRoiRosUI.baht(1250)
      "1,250 บาท"
  """
  def baht(amount) when is_integer(amount) do
    formatted =
      amount
      |> abs()
      |> Integer.to_string()
      |> String.reverse()
      |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
      |> String.reverse()

    if(amount < 0, do: "-", else: "") <> formatted <> " บาท"
  end

  # Buttons
  defdelegate button(assigns), to: Buttons

  # Controls
  defdelegate chip(assigns), to: Controls
  defdelegate chips(assigns), to: Controls
  defdelegate segment(assigns), to: Controls
  defdelegate stepper(assigns), to: Controls
  defdelegate tally_button(assigns), to: Controls
  defdelegate count_badge(assigns), to: Controls
  defdelegate cell_empty(assigns), to: Controls
  defdelegate price_row(assigns), to: Controls
  defdelegate col_head(assigns), to: Controls
  defdelegate switch(assigns), to: Controls
  defdelegate switch_row(assigns), to: Controls

  # Navigation
  defdelegate top_bar(assigns), to: Navigation
  defdelegate bottom_nav(assigns), to: Navigation

  # Layout
  defdelegate screen(assigns), to: Layout
  defdelegate card(assigns), to: Layout
  defdelegate list(assigns), to: Layout
  defdelegate list_row(assigns), to: Layout
  defdelegate section_label(assigns), to: Layout
  defdelegate hint(assigns), to: Layout
  defdelegate note_tag(assigns), to: Layout
  defdelegate footer_bar(assigns), to: Layout
  defdelegate toast(assigns), to: Layout

  # Badges
  defdelegate tag(assigns), to: Badges

  # Form
  defdelegate input(assigns), to: Form

  # Icon
  defdelegate icon(assigns), to: Icon
end
