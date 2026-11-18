defmodule SanehRoiRosUI.Controls do
  @moduledoc """
  Selection and quantity controls.

  All controls are stateless: the LiveView owns the value and handles the
  `phx-click` events. "Tap once must take effect", so every control
  emits a single event per tap.
  """
  use Phoenix.Component

  # ---------------------------------------------------------------- chip

  @doc ~S"""
  Option chip. 44px tall; selected = primary fill with
  `aria-pressed="true"`.

  Radio vs. toggle behaviour of a group is decided by the LiveView. To send
  the option as the `value` param use the native `value` attribute, not
  `phx-value-value` (the browser overwrites it with the button's `.value`).

      <UI.chips>
        <UI.chip :for={n <- @noodles} selected={n == @noodle} phx-click="noodle" phx-value-name={n}>
          {n}
        </UI.chip>
      </UI.chips>
  """
  attr :selected, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(name value disabled)
  slot :inner_block, required: true

  def chip(assigns) do
    ~H"""
    <button
      type="button"
      aria-pressed={to_string(@selected)}
      class={[
        "h-11 cursor-pointer rounded-md border-[1.5px] px-3.5 text-[15px] transition-colors duration-150",
        "disabled:cursor-not-allowed disabled:opacity-50",
        if(@selected,
          do: "border-primary bg-primary font-semibold text-white",
          else: "border-line bg-surface font-normal text-primary hover:bg-white"
        ),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  @doc "Wrapping container for chips (`flex-wrap gap-2`)."
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def chips(assigns) do
    ~H"""
    <div class={["flex flex-wrap gap-2", @class]} {@rest}>{render_slot(@inner_block)}</div>
    """
  end

  # ---------------------------------------------------------------- segment

  @doc ~S"""
  Segmented control, e.g. ถ้วย / โคน or พนักงาน / ผู้จัดการ.

  `options` is a list of `{value, label}` tuples or plain strings. Tapping an
  option sends `on_select` with the option in the `value` param (the
  button's native `value` attribute — a `phx-value-value` would be
  overwritten by the button's empty `.value` in the browser).

      <UI.segment id="ice-cream-type" options={["ถ้วย", "โคน"]} value={@type} on_select="set_type" />
  """
  attr :id, :string, required: true
  attr :options, :list, required: true
  attr :value, :any, default: nil
  attr :on_select, :any, default: nil, doc: "event name or `%JS{}`"
  attr :target, :any, default: nil, doc: "`phx-target` for the event"
  attr :class, :any, default: nil
  attr :rest, :global

  def segment(assigns) do
    assigns = assign(assigns, :options, Enum.map(assigns.options, &normalize_option/1))

    ~H"""
    <div
      id={@id}
      role="group"
      class={[
        "grid auto-cols-fr grid-flow-col gap-1 rounded-lg bg-sand p-1",
        @class
      ]}
      {@rest}
    >
      <button
        :for={{value, label} <- @options}
        id={"#{@id}-#{value}"}
        type="button"
        aria-pressed={to_string(to_string(value) == to_string(@value))}
        phx-click={@on_select}
        value={value}
        phx-target={@target}
        class={[
          "h-11 cursor-pointer rounded-sm border-0 text-[17px] transition-colors duration-150",
          if(to_string(value) == to_string(@value),
            do: "bg-primary font-bold text-white",
            else: "bg-transparent text-muted hover:text-primary"
          )
        ]}
      >
        {label}
      </button>
    </div>
    """
  end

  defp normalize_option({value, label}), do: {value, label}
  defp normalize_option(value), do: {value, value}

  # ---------------------------------------------------------------- stepper

  @doc ~S"""
  Quantity stepper `[−] N [+]`. 124×44, or compact 36px with
  `size={:sm}` (order summary).

  - value 0: muted look
  - value above 0: active look (2px primary border)
  - value at `min` (default 0): `−` is `aria-disabled` and sends nothing;
    at `max`, the same for `+`
  - reducing to 0 means "remove this item" — handled by the LiveView

  Both buttons send `on_change` with `phx-value-delta` (`-1` / `1`) plus any
  extra `params` (e.g. `%{id: item.id}`).

      <UI.stepper id={"egg-#{@bowl}"} value={@eggs} on_change="eggs" params={%{bowl: @bowl}} />
  """
  attr :id, :string, required: true
  attr :value, :integer, required: true
  attr :min, :integer, default: 0
  attr :max, :integer, default: nil
  attr :size, :atom, values: [:md, :sm], default: :md
  attr :on_change, :any, default: nil, doc: "event name or `%JS{}`"
  attr :params, :map, default: %{}, doc: "extra `phx-value-*` params"
  attr :target, :any, default: nil
  attr :label, :string, default: nil, doc: "accessible name, e.g. the item name"
  attr :class, :any, default: nil

  def stepper(assigns) do
    assigns =
      assigns
      |> assign(:active, assigns.value > 0)
      |> assign(:at_min, assigns.value <= assigns.min)
      |> assign(:at_max, assigns.max != nil and assigns.value >= assigns.max)
      |> assign(:values, phx_values(assigns.params))

    ~H"""
    <div
      id={@id}
      role="group"
      aria-label={@label}
      data-active={@active}
      class={[
        "flex flex-none items-center overflow-hidden transition-colors duration-150",
        if(@size == :sm, do: "h-9 w-auto rounded-sm", else: "h-11 w-[124px] rounded-md"),
        if(@active,
          do: "border-2 border-primary bg-white",
          else: "border-[1.5px] border-line bg-surface"
        ),
        @class
      ]}
    >
      <button
        id={"#{@id}-minus"}
        type="button"
        aria-label="ลด"
        aria-disabled={to_string(@at_min)}
        phx-click={if(!@at_min, do: @on_change)}
        phx-value-delta="-1"
        phx-target={@target}
        class={[
          "h-full border-0 p-0 text-[20px] font-bold",
          if(@size == :sm, do: "w-9", else: "w-10"),
          if(@at_min,
            do: "cursor-default bg-transparent text-disabled-soft",
            else: "cursor-pointer bg-minus text-brown active:brightness-95"
          )
        ]}
        {@values}
      >
        −
      </button>
      <span
        id={"#{@id}-value"}
        aria-live="polite"
        class={[
          "flex-1 text-center text-[17px]",
          @size == :sm && "min-w-[18px]",
          if(@active, do: "font-bold text-primary", else: "font-semibold text-disabled")
        ]}
      >
        {@value}
      </span>
      <button
        id={"#{@id}-plus"}
        type="button"
        aria-label="เพิ่ม"
        aria-disabled={to_string(@at_max)}
        phx-click={if(!@at_max, do: @on_change)}
        phx-value-delta="1"
        phx-target={@target}
        class={[
          "h-full cursor-pointer p-0 text-[20px] font-bold active:brightness-95",
          if(@size == :sm, do: "w-9", else: "w-10"),
          if(@active,
            do: "border-0 bg-primary text-white",
            else: "border-0 border-l-[1.5px] border-l-line bg-white text-primary"
          ),
          @at_max && "cursor-default opacity-50"
        ]}
        {@values}
      >
        +
      </button>
    </div>
    """
  end

  # ---------------------------------------------------------------- price grid

  @doc ~S"""
  Tally button: shows a price (or label) and counts taps; the count only goes
  up (use `stepper` to go both ways). Used in the soft drinks / water / snacks grid.
  Tap = +1. With `count > 0` it gets the "ordered" look and a badge.

      <UI.tally_button id="coke-can" price={16} count={2} phx-click="add" phx-value-sku="coke-can" />
  """
  attr :id, :string, default: nil
  attr :price, :integer, required: true
  attr :count, :integer, default: 0
  attr :label, :string, default: nil, doc: "small label above the price (e.g. ขวด)"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled name value)

  def tally_button(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      data-ordered={@count > 0}
      class={[
        "relative flex h-12 w-[76px] flex-none cursor-pointer flex-col items-center justify-center",
        "rounded-md p-0 leading-[1.15] text-primary transition-colors duration-150 active:scale-[0.97]",
        if(@count > 0,
          do: "border-2 border-primary bg-white",
          else: "border-[1.5px] border-line bg-surface hover:bg-white"
        ),
        @class
      ]}
      {@rest}
    >
      <span :if={@label} class="text-[12px] text-muted">{@label}</span>
      <span class="text-[17px] font-bold">{@price}</span>
      <.count_badge :if={@count > 0} id={@id && "#{@id}-count"} count={@count} />
    </button>
    """
  end

  @doc "Round count badge pinned to the top-right corner of its parent."
  attr :id, :string, default: nil
  attr :count, :integer, required: true

  def count_badge(assigns) do
    ~H"""
    <span
      id={@id}
      class={[
        "absolute -top-[7px] -right-1.5 flex h-[22px] min-w-[22px] items-center justify-center",
        "rounded-full bg-primary px-[5px] text-[12.5px] font-bold text-white"
      ]}
    >
      {@count}
    </span>
    """
  end

  @doc "Placeholder for a size that does not exist (renders `–`, not a button)."
  attr :class, :any, default: nil

  def cell_empty(assigns) do
    ~H"""
    <span aria-hidden="true" class={["w-[76px] flex-none text-center text-disabled-soft", @class]}>
      –
    </span>
    """
  end

  @doc ~S"""
  One row of a price grid / drinks table: name on the left, cells on the right.
  Use `name={nil}` for the header row with `<UI.col_head>` cells.
  """
  attr :name, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def price_row(assigns) do
    ~H"""
    <div class={["flex items-center gap-2 border-b border-divider py-1.5", @class]} {@rest}>
      <span class="min-w-0 flex-1 text-[16px] font-semibold">{@name}</span>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Column heading of a stepper grid, e.g. `ขวด 20`."
  attr :label, :string, required: true
  attr :price, :integer, default: nil

  def col_head(assigns) do
    ~H"""
    <span class="flex h-[34px] w-[124px] flex-none items-center justify-center gap-1.5 rounded-sm bg-primary-tint text-[18px] font-bold">
      {@label}<small :if={@price} class="text-[15px] font-semibold text-muted">{@price}</small>
    </span>
    """
  end

  # ---------------------------------------------------------------- switch

  @doc ~S"""
  On/off switch — `role="switch"` with `aria-checked`.

  The track is 52×30. Set `touch` to wrap it in a transparent 64×44 button so
  the tap target meets the 44px minimum (e.g. list rows).

      <UI.switch id="takeaway" checked={@takeaway} phx-click="toggle_takeaway" aria-label="ใส่ถุงกลับบ้าน" />
  """
  attr :id, :string, default: nil
  attr :checked, :boolean, default: false
  attr :touch, :boolean, default: false, doc: "64×44 tap target around the track"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled name value)

  def switch(%{touch: true} = assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      role="switch"
      aria-checked={to_string(@checked)}
      class={[
        "group flex h-11 w-16 flex-none cursor-pointer items-center justify-center border-0 bg-transparent p-0",
        "disabled:cursor-not-allowed disabled:opacity-50",
        @class
      ]}
      {@rest}
    >
      <span class={[
        "flex h-[30px] w-[52px] items-center rounded-full p-[3px] transition-colors duration-200",
        if(@checked, do: "bg-primary", else: "bg-switch-off")
      ]}>
        <span class={[
          "block size-6 rounded-full bg-white shadow-sm transition-transform duration-200",
          @checked && "translate-x-[22px]"
        ]} />
      </span>
    </button>
    """
  end

  def switch(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      role="switch"
      aria-checked={to_string(@checked)}
      class={[
        "flex h-[30px] w-[52px] flex-none cursor-pointer items-center rounded-full border-0 p-[3px]",
        "transition-colors duration-200 disabled:cursor-not-allowed disabled:opacity-50",
        if(@checked, do: "bg-primary", else: "bg-switch-off"),
        @class
      ]}
      {@rest}
    >
      <span class={[
        "block size-6 rounded-full bg-white shadow-sm transition-transform duration-200",
        @checked && "translate-x-[22px]"
      ]} />
    </button>
    """
  end

  @doc ~S"""
  Card row with a title, optional subtitle and a trailing switch.
  Extra attributes (e.g. `phx-click`) are forwarded to the switch.

      <UI.switch_row id="bag" title="ใส่ถุงกลับบ้าน" subtitle="ชามนี้" checked={@bag} phx-click="toggle_bag" />
  """
  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :subtitle, :string, default: nil
  attr :checked, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled name value)

  def switch_row(assigns) do
    ~H"""
    <div class={[
      "flex items-center gap-3 rounded-xl border-[1.5px] border-line-soft bg-surface py-3 pr-3 pl-4",
      @class
    ]}>
      <div class="flex flex-1 flex-col gap-0.5">
        <b id={"#{@id}-label"} class="text-[16px]">{@title}</b>
        <small :if={@subtitle} class="text-[13px] text-muted">{@subtitle}</small>
      </div>
      <.switch id={@id} checked={@checked} aria-labelledby={"#{@id}-label"} {@rest} />
    </div>
    """
  end

  @doc false
  def phx_values(params) do
    Map.new(params, fn {k, v} -> {"phx-value-#{k}", v} end)
  end
end
