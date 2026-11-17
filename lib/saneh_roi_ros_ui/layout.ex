defmodule SanehRoiRosUI.Layout do
  @moduledoc """
  Screen shell, cards, lists, footer and feedback.
  """
  use Phoenix.Component

  import SanehRoiRosUI.Icon

  alias Phoenix.LiveView.ColocatedHook

  # ---------------------------------------------------------------- screen

  @doc ~S"""
  Mobile screen shell (reference width 390px, portrait).

  The body gets 16px side padding and 110px bottom padding so it is never
  covered by the floating order bar.

      <UI.screen id="order">
        <:top><UI.top_bar title="โต๊ะ 1" back={~p"/"} /></:top>
        ...content...
        <:bottom><UI.footer_bar total={60}>…</UI.footer_bar></:bottom>
      </UI.screen>
  """
  attr :id, :string, default: nil
  attr :padded, :boolean, default: true, doc: "reserve 110px at the bottom for the order bar"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :top
  slot :inner_block, required: true
  slot :bottom

  def screen(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "relative mx-auto flex min-h-dvh w-full max-w-[390px] flex-col bg-bg font-sans text-primary",
        @class
      ]}
      {@rest}
    >
      {render_slot(@top)}
      <div class={[
        "flex flex-[1_0_auto] flex-col gap-2.5 px-4 pt-3",
        if(@padded, do: "pb-[110px]", else: "pb-4")
      ]}>
        {render_slot(@inner_block)}
      </div>
      {render_slot(@bottom)}
    </div>
    """
  end

  # ---------------------------------------------------------------- card / list

  @doc ~S"""
  Card. `variant` says how much it stands out from the page:

  - `:base` — cream surface, the normal card
  - `:elevated` — white, stands out from the cream page (e.g. summary card)
  - `:highlighted` — white with a 2px primary border (e.g. has ordered items)
  """
  attr :variant, :atom, values: [:base, :elevated, :highlighted], default: :base
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def card(assigns) do
    ~H"""
    <div
      data-variant={@variant}
      class={[
        "flex flex-col gap-2.5 rounded-lg p-3.5",
        card_classes(@variant),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp card_classes(:base), do: "border-[1.5px] border-line-soft bg-surface"
  defp card_classes(:elevated), do: "border-[1.5px] border-line-soft bg-white"
  defp card_classes(:highlighted), do: "border-2 border-primary bg-white"

  @doc "Grouped list container with dividers between `list_row`s."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def list(assigns) do
    ~H"""
    <div
      class={[
        "overflow-hidden rounded-lg border-[1.5px] border-line-soft bg-surface",
        "[&>*:not(:last-child)]:border-b [&>*:not(:last-child)]:border-divider",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc ~S"""
  List row: min-height 64, title 16/700, subtitle 13 muted.

  Renders as a link with `navigate`/`patch`/`href`, as a button when it has a
  `phx-click` and no `:trailing` slot, and as a plain `div` otherwise (so a
  trailing control such as a switch is never nested inside a button).
  Interactive rows show a `›` chevron unless `:trailing` is given.

      <UI.list_row title="รายชื่อพนักงาน" subtitle="ใช้งาน 4 คน" navigate={~p"/staff"}>
        <:icon><.icon name="hero-users" class="size-5" /></:icon>
      </UI.list_row>

      <UI.list_row title="เย็นตาโฟต้มยำ" soldout>
        <:badge><UI.tag variant={:accent}>หมดวันนี้</UI.tag></:badge>
        <:trailing><UI.switch checked={false} phx-click="toggle" /></:trailing>
      </UI.list_row>
  """
  attr :id, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :soldout, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch replace disabled)
  slot :icon
  slot :badge, doc: "rendered inline after the title (e.g. a sold-out tag)"
  slot :trailing

  def list_row(%{rest: rest} = assigns) do
    {link?, rest} = SanehRoiRosUI.NavAttrs.split(rest)
    assigns = assign(assigns, :rest, rest)

    as =
      cond do
        link? -> :link
        rest[:"phx-click"] && assigns.trailing == [] -> :button
        true -> :div
      end

    assigns =
      assigns
      |> assign(:as, as)
      |> assign(:row_class, [
        "flex min-h-16 w-full items-center gap-3 border-0 bg-transparent px-3 py-2.5 text-left text-primary",
        as != :div && "cursor-pointer transition-colors duration-150 hover:bg-white",
        assigns.soldout && "bg-soldout",
        assigns.class
      ])

    ~H"""
    <.link :if={@as == :link} id={@id} class={@row_class} data-soldout={@soldout} {@rest}>
      <.list_row_content {assigns} chevron />
    </.link>
    <button
      :if={@as == :button}
      id={@id}
      type="button"
      class={@row_class}
      data-soldout={@soldout}
      {@rest}
    >
      <.list_row_content {assigns} chevron />
    </button>
    <div :if={@as == :div} id={@id} class={@row_class} data-soldout={@soldout} {@rest}>
      <.list_row_content {assigns} chevron={false} />
    </div>
    """
  end

  attr :chevron, :boolean, required: true
  attr :title, :string, required: true
  attr :subtitle, :string
  attr :soldout, :boolean
  attr :icon, :list
  attr :badge, :list
  attr :trailing, :list
  attr :rest, :any
  attr :class, :any
  attr :id, :any
  attr :as, :atom
  attr :row_class, :any

  defp list_row_content(assigns) do
    ~H"""
    <span
      :if={@icon != []}
      class="flex size-10 flex-none items-center justify-center rounded-md bg-primary-tint"
    >
      {render_slot(@icon)}
    </span>
    <span class={["flex flex-1 flex-col leading-[1.3]", @soldout && "opacity-60"]}>
      <b class="flex flex-wrap items-center gap-2 text-[16px]">{@title}{render_slot(@badge)}</b>
      <small :if={@subtitle} class="text-[13px] text-muted">{@subtitle}</small>
    </span>
    {render_slot(@trailing)}
    <.icon
      :if={@chevron && @trailing == []}
      name="hero-chevron-right"
      class="size-5 flex-none text-icon"
    />
    """
  end

  @doc "Small uppercase-style label above a group of rows."
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def section_label(assigns) do
    ~H"""
    <span class={["pl-1 text-[13px] font-bold text-muted", @class]}>{render_slot(@inner_block)}</span>
    """
  end

  # ---------------------------------------------------------------- hint / note

  @doc "Sand-coloured note / hint box."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def hint(assigns) do
    ~H"""
    <div
      class={["rounded-md bg-sand px-3.5 py-3 text-[14px] leading-normal text-note", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc ~S'Inline item note, e.g. `หมายเหตุ: แยกน้ำ`.'
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def note_tag(assigns) do
    ~H"""
    <span
      class={[
        "self-start rounded-[8px] bg-note-bg px-2 py-0.5 text-[14px] font-semibold text-brown",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  # ---------------------------------------------------------------- footer

  @doc ~S"""
  Sticky footer for option/summary pages: optional "รวม … บาท" row
  and the action buttons.

      <UI.footer_bar total={60}>
        <UI.button variant={:primary} block phx-click="done">เสร็จ · 60</UI.button>
      </UI.footer_bar>
  """
  attr :id, :string, default: nil
  attr :total, :integer, default: nil
  attr :total_label, :string, default: "รวม"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def footer_bar(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "sticky bottom-0 z-10 flex flex-col gap-2.5 border-t border-line-soft bg-bg px-4 pt-3 pb-5",
        @class
      ]}
      {@rest}
    >
      <div :if={@total} class="flex items-baseline justify-between">
        <span class="text-[15px] text-muted">{@total_label}</span>
        <b class="text-[28px]" data-role="total">{SanehRoiRosUI.baht(@total)}</b>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  # ---------------------------------------------------------------- toast

  @doc ~S"""
  Toast: dark pill above the order bar with an optional action
  (e.g. "ยกเลิก" for undo). Disappears by itself after `duration` ms
  (default ~4s; `0` keeps it).

  Change `key` whenever a new message is shown so the timer restarts.
  When `on_dismiss` is set, the hook pushes that event once the toast hides,
  so the LiveView can clear its assign.

      <UI.toast :if={@toast} id="toast" key={@toast.key} action="ยกเลิก" on_action="undo" on_dismiss="clear_toast">
        {@toast.message}
      </UI.toast>
  """
  attr :id, :string, required: true
  attr :key, :any, default: nil, doc: "change it to restart the auto-dismiss timer"
  attr :action, :string, default: nil, doc: "action button label"
  attr :on_action, :any, default: nil, doc: "event name or `%JS{}` for the action button"
  attr :on_dismiss, :string, default: nil, doc: "event pushed after auto-dismiss"
  attr :duration, :integer, default: 4000
  attr :position, :atom, values: [:fixed, :absolute], default: :fixed
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def toast(assigns) do
    ~H"""
    <div
      id={@id}
      role="status"
      aria-live="polite"
      phx-hook=".Toast"
      data-key={@key}
      data-duration={@duration}
      data-on-dismiss={@on_dismiss}
      class={[
        "inset-x-4 bottom-[92px] z-30 mx-auto flex min-h-12 max-w-[358px] items-center gap-2.5",
        "rounded-md bg-wait-ink py-1 pr-1.5 pl-3.5 text-[14.5px] text-white",
        @position,
        @class
      ]}
      {@rest}
    >
      <span class="flex-1">{render_slot(@inner_block)}</span>
      <button
        :if={@action}
        id={"#{@id}-action"}
        type="button"
        phx-click={@on_action}
        class="h-[38px] cursor-pointer rounded-sm border-0 bg-wait px-3 text-[14px] font-bold text-wait-ink active:brightness-95"
      >
        {@action}
      </button>
    </div>
    <script :type={ColocatedHook} name=".Toast">
      export default {
        mounted() { this.arm() },
        updated() {
          if (this.el.dataset.key !== this.key) {
            this.js().show(this.el, {display: "flex"})
            this.arm()
          }
        },
        destroyed() { clearTimeout(this.timer) },
        arm() {
          clearTimeout(this.timer)
          this.key = this.el.dataset.key
          const ms = parseInt(this.el.dataset.duration || "4000", 10)
          if (ms > 0) this.timer = setTimeout(() => this.dismiss(), ms)
        },
        dismiss() {
          this.js().hide(this.el, {
            transition: ["transition-opacity duration-200", "opacity-100", "opacity-0"],
            time: 200
          })
          const event = this.el.dataset.onDismiss
          if (event) this.pushEvent(event, {id: this.el.id, key: this.key})
        }
      }
    </script>
    """
  end
end
