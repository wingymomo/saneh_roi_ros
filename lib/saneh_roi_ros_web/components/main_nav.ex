defmodule SanehRoiRosWeb.MainNav do
  @moduledoc """
  The app's bottom navigation: รับออเดอร์ · จัดการเมนู · ยอดขาย · บัญชี · ตั้งค่า,
  with the role permissions.

  Items the role may not open stay visible but grey. Tapping one shows a
  "… เปิดได้เฉพาะ…" toast; this module handles that itself, so pages need
  no event handler:

      on_mount SanehRoiRosWeb.Toast
      on_mount SanehRoiRosWeb.MainNav

      <.main_nav current={:orders} role={@current_staff.role} />
      <.app_toast toast={@toast} />
  """
  use Phoenix.Component

  import Phoenix.LiveView, only: [attach_hook: 4]

  alias SanehRoiRosWeb.Toast

  @denied_event "main_nav_denied"

  @items [
    %{key: :orders, label: "รับออเดอร์", icon: "hero-clipboard-document-list", path: "/"},
    %{key: :menu, label: "จัดการเมนู", icon: "hero-book-open", path: "/menu"},
    %{key: :sales, label: "ยอดขาย", icon: "hero-chart-bar", path: "/sales"},
    %{key: :accounts, label: "บัญชี", icon: "hero-banknotes", path: "/accounts"},
    %{key: :settings, label: "ตั้งค่า", icon: "hero-cog-6-tooth", path: "/settings"}
  ]

  @permissions %{
    orders: [:staff, :manager, :owner],
    menu: [:manager, :owner],
    sales: [:owner],
    accounts: [:owner],
    settings: [:owner]
  }

  # ---------------------------------------------------------------- lifecycle

  @doc false
  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> Toast.ensure_mounted!(__MODULE__)
     |> attach_hook(:main_nav, :handle_event, &handle_event/3)}
  end

  @doc false
  def handle_event(@denied_event, %{"item" => item}, socket),
    do: {:halt, Toast.put(socket, denied_message(item))}

  def handle_event(_event, _params, socket), do: {:cont, socket}

  # ---------------------------------------------------------------- component

  @doc """
  Bottom navigation for `role`, with `current` highlighted.
  """
  attr :role, :atom, values: [:staff, :manager, :owner], required: true
  attr :current, :atom, default: nil
  attr :paths, :map, default: %{}, doc: "override item paths, e.g. `%{menu: ~p\"/menu\"}`"
  attr :id, :string, default: "bottom-nav"
  attr :position, :atom, values: [:fixed, :absolute, :static], default: :fixed
  attr :class, :any, default: nil

  def main_nav(assigns) do
    assigns = assign(assigns, :items, items(assigns.role, assigns.paths))

    ~H"""
    <SanehRoiRosUI.bottom_nav
      id={@id}
      items={@items}
      current={@current}
      on_disabled="main_nav_denied"
      position={@position}
      class={@class}
    />
    """
  end

  # ---------------------------------------------------------------- permissions

  @doc """
  Nav items for `role`; items it may not open are `disabled: true`.
  """
  def items(role, paths \\ %{}) do
    for item <- @items do
      item
      |> Map.put(:path, Map.get(paths, item.key, item.path))
      |> Map.put(:disabled, not allowed?(role, item.key))
    end
  end

  @doc """
  Whether `role` may open `item` (atom, or the string sent by `phx-value-item`).

      iex> SanehRoiRosWeb.MainNav.allowed?(:manager, :menu)
      true
      iex> SanehRoiRosWeb.MainNav.allowed?(:staff, "sales")
      false
  """
  def allowed?(role, item), do: role in Map.get(@permissions, to_item(item), [])

  @doc """
  Toast text for a denied item.

      iex> SanehRoiRosWeb.MainNav.denied_message(:sales)
      "ยอดขาย เปิดได้เฉพาะเจ้าของร้าน"
      iex> SanehRoiRosWeb.MainNav.denied_message("menu")
      "จัดการเมนู เปิดได้เฉพาะผู้จัดการและเจ้าของร้าน"
  """
  def denied_message(item) do
    item = to_item(item)
    label = Enum.find_value(@items, "เมนูนี้", &(&1.key == item && &1.label))

    case Map.get(@permissions, item) do
      [:manager, :owner] -> "#{label} เปิดได้เฉพาะผู้จัดการและเจ้าของร้าน"
      _ -> "#{label} เปิดได้เฉพาะเจ้าของร้าน"
    end
  end

  defp to_item(item) when is_atom(item), do: item

  defp to_item(item) when is_binary(item) do
    Enum.find_value(@items, &(Atom.to_string(&1.key) == item && &1.key))
  end
end
