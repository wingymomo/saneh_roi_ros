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
  attr :size, :atom, values: [:xl, :lg, :md], default: :xl, doc: "title size: 24 / 22 / 20"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :actions

  def top_bar(assigns) do
    ~H"""
    <header
      id={@id}
      class={[
        "flex items-center gap-1 pt-2 pr-3 pb-1",
        if(@back, do: "pl-1", else: "pl-4"),
        @class
      ]}
      {@rest}
    >
      <.link
        :if={@back}
        navigate={@back}
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
    </header>
    """
  end

  defp title_size(:xl), do: "text-[24px] font-bold"
  defp title_size(:lg), do: "text-[22px] font-bold"
  defp title_size(:md), do: "text-[20px] font-bold"

  # ---------------------------------------------------------------- bottom nav

  @doc ~S"""
  Bottom navigation bar: up to 5 items, icon + label.

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
    ~H"""
    <nav
      id={@id}
      aria-label="เมนูหลัก"
      class={[
        "inset-x-0 bottom-0 z-20 mx-auto grid h-[72px] max-w-[390px] auto-cols-fr grid-flow-col",
        "border-t border-line-soft bg-bg pb-1.5",
        @position,
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
            if(item.key == @current,
              do: "font-bold text-primary",
              else: "text-muted hover:text-primary"
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
          class="flex cursor-pointer flex-col items-center justify-center gap-0.5 text-[12.5px] text-disabled"
        >
          <.icon name={item.icon} class="size-6" />
          <span>{item.label}</span>
        </a>
      <% end %>
    </nav>
    """
  end
end
