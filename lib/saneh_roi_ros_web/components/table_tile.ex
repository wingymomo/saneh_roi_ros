defmodule SanehRoiRosWeb.TableTile do
  @moduledoc """
  Table floor plan on the home page (app-specific: knows the table states —
  free, or busy with the queue number of every sent round).
  """
  use Phoenix.Component

  @doc "3-column grid for `table_tile`s."
  attr :id, :string, default: nil
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def table_grid(assigns) do
    ~H"""
    <div
      id={@id}
      class={["grid auto-rows-[96px] grid-cols-3 gap-2.5", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc ~S"""
  Table tile on the floor plan.

  - no queues → ว่าง (surface)
  - with queues → มีลูกค้า (wait colours) + pill listing **every** round's
    queue number, e.g. `#3 #7`

  There is no "cooking" state: a table is free again only after payment.

      <.table_tile id="table-1" number={1} queues={[3, 7]} phx-click="open" phx-value-table="1" />
  """
  attr :id, :string, default: nil
  attr :number, :any, required: true
  attr :queues, :list, default: [], doc: "queue numbers of every sent round"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch disabled)

  def table_tile(%{rest: rest} = assigns) do
    {link?, rest} = SanehRoiRosUI.NavAttrs.split(rest)

    assigns =
      assigns
      |> assign(:busy, assigns.queues != [])
      |> assign(link?: link?, rest: rest)

    ~H"""
    <.link
      :if={@link?}
      id={@id}
      class={tile_class(@busy, @class)}
      data-busy={@busy}
      aria-label={tile_label(@number, @busy)}
      {@rest}
    >
      <.table_tile_content number={@number} queues={@queues} busy={@busy} />
    </.link>
    <button
      :if={!@link?}
      id={@id}
      type="button"
      class={tile_class(@busy, @class)}
      data-busy={@busy}
      aria-label={tile_label(@number, @busy)}
      {@rest}
    >
      <.table_tile_content number={@number} queues={@queues} busy={@busy} />
    </button>
    """
  end

  defp tile_class(busy, extra) do
    [
      "relative flex cursor-pointer flex-col items-center justify-center gap-1.5 rounded-xl border-[1.5px] p-1.5",
      "transition-transform duration-150 active:scale-[0.97] disabled:cursor-not-allowed disabled:opacity-45",
      if(busy,
        do: "border-wait-line bg-wait text-wait-ink",
        else: "border-line bg-surface text-primary hover:bg-white"
      ),
      extra
    ]
  end

  defp tile_label(number, true), do: "โต๊ะ #{number} มีลูกค้า"
  defp tile_label(number, false), do: "โต๊ะ #{number} ว่าง"

  attr :number, :any, required: true
  attr :queues, :list, required: true
  attr :busy, :boolean, required: true

  defp table_tile_content(assigns) do
    ~H"""
    <span
      :if={@busy}
      data-role="queues"
      class="absolute top-1.5 left-1.5 flex h-5 items-center rounded-full bg-wait-ink px-[7px] text-[11.5px] font-bold text-white"
    >
      {Enum.map_join(@queues, " ", &"##{&1}")}
    </span>
    <span class="text-[26px] leading-none font-bold">{@number}</span>
    <span class={["text-[12.5px] font-semibold", !@busy && "text-muted"]}>
      {if @busy, do: "มีลูกค้า", else: "ว่าง"}
    </span>
    """
  end
end
