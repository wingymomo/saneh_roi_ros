defmodule SanehRoiRosWeb.OrderBar do
  @moduledoc """
  Floating order summary bar on the ordering pages (app-specific: order
  wording and flow).
  """
  use Phoenix.Component

  @doc ~S"""
  Floating order summary bar: item count, "ยังไม่ส่งครัว", total and
  a white CTA. Attributes such as `phx-click` or `navigate` go to the CTA.

  `position={:fixed}` (default) pins it to the viewport; `:absolute` pins it
  to the nearest positioned ancestor (e.g. `<UI.screen>` or a demo frame).

      <.order_bar id="order-bar" count={3} total={170} navigate={~p"/tables/1/summary"} />
  """
  attr :id, :string, default: "order-bar"
  attr :count, :integer, required: true
  attr :total, :integer, required: true
  attr :caption, :string, default: "ยังไม่ส่งครัว"
  attr :cta, :string, default: "สรุปออเดอร์ →"
  attr :position, :atom, values: [:fixed, :absolute], default: :fixed
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch replace disabled)

  def order_bar(%{rest: rest} = assigns) do
    {link?, rest} = SanehRoiRosUI.NavAttrs.split(rest)
    assigns = assign(assigns, link?: link?, rest: rest)

    ~H"""
    <div
      id={@id}
      class={[
        "inset-x-3 bottom-4 z-20 mx-auto flex h-16 max-w-[366px] items-center gap-3",
        "rounded-2xl bg-primary pr-2 pl-3 text-white shadow-bar",
        @position,
        @class
      ]}
    >
      <span
        id={"#{@id}-count"}
        class="flex size-8 flex-none items-center justify-center rounded-full bg-white text-[15px] font-bold text-primary"
      >
        {@count}
      </span>
      <span class="flex flex-1 flex-col leading-tight">
        <small class="text-[13px] opacity-85">{@caption}</small>
        <b id={"#{@id}-total"} class="text-[19px]">{SanehRoiRosUI.baht(@total)}</b>
      </span>
      <.link
        :if={@link?}
        id={"#{@id}-cta"}
        class="flex h-12 items-center rounded-md bg-white px-[18px] text-[16px] font-bold text-primary transition-transform active:scale-[0.97]"
        {@rest}
      >
        {@cta}
      </.link>
      <button
        :if={!@link?}
        id={"#{@id}-cta"}
        type="button"
        class="h-12 cursor-pointer rounded-md border-0 bg-white px-[18px] text-[16px] font-bold text-primary transition-transform active:scale-[0.97]"
        {@rest}
      >
        {@cta}
      </button>
    </div>
    """
  end
end
