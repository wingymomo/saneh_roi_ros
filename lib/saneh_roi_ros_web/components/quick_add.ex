defmodule SanehRoiRosWeb.QuickAdd do
  @moduledoc """
  Tap-once adding with an undo toast (soft drinks, water, snacks…).

  Each tap on a `quick_add_button/1` adds 1 to that item's count and shows a
  toast "เพิ่ม … แล้ว (รวม N)" with an "ยกเลิก" action that takes the tap
  back. The toast itself is `SanehRoiRosWeb.Toast`.

  Mount both; this module attaches its own event handlers, so the LiveView
  does not need any:

      on_mount SanehRoiRosWeb.Toast
      on_mount SanehRoiRosWeb.QuickAdd

      <.quick_add_button sku="coke-can" label="โค้ก กระป๋อง" price={16} counts={@quick_add_counts} />
      <.app_toast toast={@toast} />

  It keeps `@quick_add_counts` (`%{sku => count}`) and handles
  `"quick_add"` and `"quick_add_undo"`.
  """
  use Phoenix.Component

  import Phoenix.LiveView, only: [attach_hook: 4]

  alias SanehRoiRosWeb.Toast

  @add_event "quick_add"
  @undo_event "quick_add_undo"

  # ---------------------------------------------------------------- lifecycle

  @doc false
  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> Toast.ensure_mounted!(__MODULE__)
     |> assign(:quick_add_counts, %{})
     |> attach_hook(:quick_add, :handle_event, &handle_event/3)}
  end

  @doc false
  def handle_event(@add_event, %{"sku" => sku, "label" => label}, socket),
    do: {:halt, add(socket, sku, label)}

  def handle_event(@undo_event, _params, socket), do: {:halt, undo(socket)}

  def handle_event(_event, _params, socket), do: {:cont, socket}

  # ---------------------------------------------------------------- state

  @doc "Adds one `sku` and shows the undo toast."
  def add(socket, sku, label) do
    counts = Map.update(socket.assigns.quick_add_counts, sku, 1, &(&1 + 1))

    socket
    |> assign(:quick_add_counts, counts)
    |> Toast.put("เพิ่ม #{label} แล้ว (รวม #{counts[sku]})",
      action: "ยกเลิก",
      on_action: @undo_event,
      meta: {__MODULE__, sku}
    )
  end

  @doc "Takes back the add shown in the current toast (if it is ours) and hides the toast."
  def undo(socket) do
    case socket.assigns.toast do
      %{meta: {__MODULE__, sku}} ->
        counts =
          case Map.get(socket.assigns.quick_add_counts, sku, 0) do
            n when n <= 1 -> Map.delete(socket.assigns.quick_add_counts, sku)
            n -> Map.put(socket.assigns.quick_add_counts, sku, n - 1)
          end

        socket
        |> assign(:quick_add_counts, counts)
        |> Toast.clear()

      _ ->
        socket
    end
  end

  @doc "Sets the counts, e.g. when restoring an order that is still open."
  def put_counts(socket, counts) when is_map(counts),
    do: assign(socket, :quick_add_counts, counts)

  @doc "Count of `sku`."
  def count(counts, sku), do: Map.get(counts, sku, 0)

  @doc "Total number of items added."
  def total_count(counts), do: counts |> Map.values() |> Enum.sum()

  # ---------------------------------------------------------------- component

  @doc """
  Tally button that adds one on every tap and shows the running count.
  """
  attr :sku, :string, required: true
  attr :label, :string, required: true, doc: "item name for the toast, e.g. โค้ก กระป๋อง"
  attr :price, :integer, required: true
  attr :counts, :map, required: true, doc: "`@quick_add_counts`"
  attr :id, :string, default: nil, doc: "defaults to `quick-add-<sku>`"
  attr :rest, :global

  def quick_add_button(assigns) do
    ~H"""
    <SanehRoiRosUI.tally_button
      id={@id || "quick-add-#{@sku}"}
      price={@price}
      count={count(@counts, @sku)}
      aria-label={"#{@label} #{@price} บาท"}
      phx-click="quick_add"
      phx-value-sku={@sku}
      phx-value-label={@label}
      {@rest}
    />
    """
  end
end
