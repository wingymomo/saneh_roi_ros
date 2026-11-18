defmodule SanehRoiRosUI.Navigation do
  @moduledoc """
  Top bar and bottom navigation.
  """
  use Phoenix.Component

  import SanehRoiRosUI.Icon

  # ---------------------------------------------------------------- top bar

  @doc ~S"""
  Top bar: 44×44 back button, title 24/700 with optional subtitle, and a
  trailing slot for a secondary action (ย้ายโต๊ะ, + สั่งเพิ่ม, role badge,
  staff name + ออก).

      <UI.top_bar id="top" title="โต๊ะ 1" subtitle="รอบที่ 2" back={~p"/"}>
        <:actions><UI.button size={:sm}>ย้ายโต๊ะ</UI.button></:actions>
      </UI.top_bar>
  """
  attr :id, :string, default: nil
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :back, :any, default: nil, doc: "path to navigate back to; no back button when nil"

  attr :back_patch, :boolean,
    default: false,
    doc: "go back with a live patch (same LiveView, keeps its state) instead of navigate"

  attr :size, :atom, values: [:xl, :lg, :md], default: :xl, doc: "title size: 24 / 22 / 20"
  attr :class, :any, default: nil
  attr :inner_class, :any, default: nil, doc: "classes for the content, e.g. a max width"
  attr :rest, :global
  slot :actions

  def top_bar(assigns) do
    ~H"""
    <header
      id={@id}
      class={["pt-2 pb-1", @class]}
      {@rest}
    >
      <div class={[
        "flex items-center gap-1 pr-3 md:pr-6 lg:pr-8",
        if(@back, do: "pl-1 md:pl-3 lg:pl-5", else: "pl-4 md:pl-6 lg:pl-8"),
        @inner_class
      ]}>
        <.link
          :if={@back && !@back_patch}
          navigate={@back}
          aria-label="ย้อนกลับ"
          class="flex size-11 flex-none items-center justify-center rounded-md text-primary transition-colors hover:bg-sand"
        >
          <.icon name="hero-chevron-left" class="size-[22px]" />
        </.link>
        <.link
          :if={@back && @back_patch}
          patch={@back}
          aria-label="ย้อนกลับ"
          class="flex size-11 flex-none items-center justify-center rounded-md text-primary transition-colors hover:bg-sand"
        >
          <.icon name="hero-chevron-left" class="size-[22px]" />
        </.link>
        <div class="flex flex-1 flex-col leading-tight">
          <b class={title_size(@size)}>{@title}</b>
          <small :if={@subtitle} class="text-[13px] text-muted">{@subtitle}</small>
        </div>
        <div :if={@actions != []} class="flex flex-none items-center gap-2">
          {render_slot(@actions)}
        </div>
      </div>
    </header>
    """
  end

  defp title_size(:xl), do: "text-[24px] font-bold"
  defp title_size(:lg), do: "text-[22px] font-bold"
  defp title_size(:md), do: "text-[20px] font-bold"

  # ---------------------------------------------------------------- bottom nav

  @doc ~S"""
  Main navigation: up to 5 items, icon + label. A bottom bar on phones. With
  the default `position={:fixed}` it becomes a side rail from `md:` and a
  wider sidebar from `lg:`; offset the page with `md:pl-24 lg:pl-56`.

  Each item is a map with `:key`, `:label`, `:icon` (a `hero-*` name) and
  `:path`, plus optional `:disabled`. Disabled items stay visible but grey
  (`aria-disabled`, no lock icon) and send `on_disabled` with
  `phx-value-item` (the item key) instead of navigating.

      <UI.bottom_nav
        current={:orders}
        items={[
          %{key: :orders, label: "รับออเดอร์", icon: "hero-clipboard-document-list", path: "/"},
          %{key: :sales, label: "ยอดขาย", icon: "hero-chart-bar", path: "/sales", disabled: true}
        ]}
        on_disabled="nav_disabled"
      />
  """
  attr :id, :string, default: "bottom-nav"
  attr :items, :list, required: true
  attr :current, :atom, default: nil
  attr :on_disabled, :any, default: nil, doc: "event name or `%JS{}`; gets `phx-value-item`"
  attr :position, :atom, values: [:fixed, :absolute, :static], default: :fixed
  attr :class, :any, default: nil
  attr :rest, :global

  def bottom_nav(assigns) do
    # Breakpoints follow the viewport, so a nav placed inside a phone-sized
    # frame (`:absolute` / `:static`) must stay a bottom bar.
    assigns = assign(assigns, :rail, assigns.position == :fixed)

    ~H"""
    <nav
      id={@id}
      aria-label="เมนูหลัก"
      class={[
        "inset-x-0 bottom-0 z-20 grid h-[72px] auto-cols-fr grid-flow-col",
        "border-t border-line-soft bg-bg pb-1.5",
        @position,
        @rail &&
          [
            "md:inset-x-auto md:top-0 md:left-0 md:h-dvh md:w-24 md:auto-rows-[72px] md:grid-flow-row",
            "md:content-start md:gap-1 md:border-t-0 md:border-r md:p-2",
            "lg:w-56 lg:auto-rows-12 lg:p-3"
          ],
        @class
      ]}
      {@rest}
    >
      <%= for item <- @items do %>
        <.link
          :if={!item[:disabled]}
          id={"#{@id}-#{item.key}"}
          navigate={item.path}
          aria-current={if(item.key == @current, do: "page")}
          class={[
            "flex flex-col items-center justify-center gap-0.5 text-[12.5px] transition-colors",
            @rail && rail_item_classes(),
            if(item.key == @current,
              do: ["font-bold text-primary", @rail && "md:bg-primary-tint"],
              else: ["text-muted hover:text-primary", @rail && "md:hover:bg-sand"]
            )
          ]}
        >
          <.icon name={item.icon} class="size-6" />
          <span>{item.label}</span>
        </.link>
        <a
          :if={item[:disabled]}
          id={"#{@id}-#{item.key}"}
          role="link"
          aria-disabled="true"
          phx-click={@on_disabled}
          phx-value-item={item.key}
          class={[
            "flex cursor-pointer flex-col items-center justify-center gap-0.5 text-[12.5px] text-disabled",
            @rail && rail_item_classes()
          ]}
        >
          <.icon name={item.icon} class="size-6" />
          <span>{item.label}</span>
        </a>
      <% end %>
    </nav>
    """
  end

  defp rail_item_classes do
    "md:rounded-md lg:flex-row lg:justify-start lg:gap-3 lg:px-3 lg:text-[15px]"
  end
end
