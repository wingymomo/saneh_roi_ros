defmodule SanehRoiRosWeb.Login do
  @moduledoc """
  Login screen pieces (app-specific): staff name tiles, PIN dots and the
  number keypad.
  """
  use Phoenix.Component

  alias SanehRoiRosWeb.RoleTag

  @doc ~S"""
  Staff name tile: 96px, avatar with the first letter, name and role
  (managers' role shown in brown).

      <.name_tile id="staff-1" name="นิด" role={:staff} selected phx-click="pick" phx-value-id="1" />
  """
  attr :id, :string, default: nil
  attr :name, :string, required: true
  attr :role, :atom, values: [:staff, :manager, :owner], required: true
  attr :selected, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(disabled name value)

  def name_tile(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      aria-pressed={to_string(@selected)}
      class={[
        "flex h-24 cursor-pointer flex-col items-center justify-center gap-1 rounded-xl transition-colors duration-150",
        if(@selected,
          do: "border-2 border-primary bg-primary text-white",
          else: "border-[1.5px] border-line bg-surface text-primary hover:bg-white"
        ),
        @class
      ]}
      {@rest}
    >
      <span class={[
        "flex size-10 items-center justify-center rounded-full text-[17px] font-bold",
        if(@selected, do: "bg-white text-primary", else: "bg-primary-tint text-primary")
      ]}>
        {String.first(@name)}
      </span>
      <b class="text-[15px]">{@name}</b>
      <small class={[
        "text-[12px] font-semibold",
        cond do
          @selected -> "text-white opacity-85"
          @role == :manager -> "text-brown"
          true -> "text-muted"
        end
      ]}>
        {RoleTag.role_label(@role)}
      </small>
    </button>
    """
  end

  @doc ~S"""
  PIN dots: filled = primary, empty = dashed-colour ring.

      <.pin_dots id="pin" filled={String.length(@pin)} />
  """
  attr :id, :string, default: nil
  attr :filled, :integer, required: true
  attr :length, :integer, default: 4
  attr :class, :any, default: nil

  def pin_dots(assigns) do
    ~H"""
    <div
      id={@id}
      role="img"
      aria-label={"ใส่รหัสแล้ว #{min(@filled, @length)} จาก #{@length} หลัก"}
      class={["flex justify-center gap-4", @class]}
    >
      <span
        :for={i <- 1..@length}
        data-filled={i <= @filled}
        class={[
          "size-[18px] rounded-full border-2 transition-colors duration-150",
          if(i <= @filled, do: "border-primary bg-primary", else: "border-line-dashed")
        ]}
      />
    </div>
    """
  end

  @doc ~S"""
  Number keypad (3×4, 64px keys). Digits send `on_digit` with
  `phx-value-digit`; ⌫ sends `on_backspace`. The bottom-left key is an
  optional text action (e.g. "สุ่มให้").

      <.keypad id="keypad" on_digit="digit" on_backspace="backspace" on_extra="random">
        <:extra>สุ่มให้</:extra>
      </.keypad>
  """
  attr :id, :string, required: true
  attr :on_digit, :any, default: nil
  attr :on_backspace, :any, default: nil
  attr :target, :any, default: nil
  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :on_extra, :any, default: nil, doc: "event for the `:extra` key"
  slot :extra, doc: "label of the bottom-left text key (e.g. สุ่มให้)"

  def keypad(assigns) do
    ~H"""
    <div id={@id} class={["grid grid-cols-3 gap-2.5", @class]}>
      <button
        :for={d <- ~w(1 2 3 4 5 6 7 8 9)}
        id={"#{@id}-#{d}"}
        type="button"
        class={key_class()}
        phx-click={@on_digit}
        phx-value-digit={d}
        phx-target={@target}
        disabled={@disabled}
      >
        {d}
      </button>
      <%= if @extra == [] do %>
        <span aria-hidden="true"></span>
      <% else %>
        <button
          :for={extra <- @extra}
          id={"#{@id}-extra"}
          type="button"
          class={[key_class(), "text-[15px] font-bold"]}
          disabled={@disabled}
          phx-click={@on_extra}
          phx-target={@target}
        >
          {render_slot(extra)}
        </button>
      <% end %>
      <button
        id={"#{@id}-0"}
        type="button"
        class={key_class()}
        phx-click={@on_digit}
        phx-value-digit="0"
        phx-target={@target}
        disabled={@disabled}
      >
        0
      </button>
      <button
        id={"#{@id}-backspace"}
        type="button"
        aria-label="ลบ"
        class={key_class()}
        phx-click={@on_backspace}
        phx-target={@target}
        disabled={@disabled}
      >
        ⌫
      </button>
    </div>
    """
  end

  defp key_class do
    [
      "h-16 cursor-pointer rounded-xl border-[1.5px] border-line bg-surface text-[26px] font-semibold text-primary",
      "transition-[background-color,transform] duration-100 hover:bg-white active:scale-[0.96] active:bg-sand",
      "disabled:cursor-not-allowed disabled:opacity-50"
    ]
  end
end
