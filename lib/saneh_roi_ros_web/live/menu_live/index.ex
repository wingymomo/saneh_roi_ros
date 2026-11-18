defmodule SanehRoiRosWeb.MenuLive.Index do
  @moduledoc """
  จัดการเมนู (1a): menu list by category, search, and the
  "เปิดขาย / หมดวันนี้" switch on every item.
  """
  use SanehRoiRosWeb, :live_view

  alias SanehRoiRos.Menu
  alias SanehRoiRos.Menu.OptionGroup
  alias SanehRoiRosWeb.Toast

  @impl true
  def mount(_params, _session, socket) do
    categories = Menu.list_categories()

    socket =
      socket
      |> assign(:page_title, "จัดการเมนู")
      |> assign(:categories, categories)
      |> assign(:search, "")
      |> assign(:search_form, to_form(%{"q" => ""}, as: :search))
      |> show_flash_as_toast()

    {:ok, socket}
  end

  # A flash set by the form page ("บันทึกเมนูแล้ว") is shown with the page's toast.
  defp show_flash_as_toast(socket) do
    case Phoenix.Flash.get(socket.assigns.flash, :info) do
      nil -> socket
      message -> socket |> clear_flash(:info) |> Toast.put(message)
    end
  end

  @impl true
  def handle_params(params, _uri, socket) do
    category = pick_category(socket.assigns.categories, params["category"])

    {:noreply,
     socket
     |> assign(:category, category)
     |> load_items()}
  end

  defp pick_category([], _id), do: nil

  defp pick_category([first | _] = categories, id) do
    Enum.find(categories, first, &(to_string(&1.id) == id))
  end

  # The date is read on every load/toggle so a screen left open past midnight
  # does not mark items sold out "yesterday".
  defp load_items(socket) do
    socket = assign(socket, :today, Menu.today())
    %{category: category, search: search} = socket.assigns

    items =
      cond do
        String.trim(search) != "" -> Menu.list_items(nil, search: search)
        category -> Menu.list_items(category.id)
        true -> []
      end

    socket
    |> assign(:item_count, length(items))
    |> assign(:status, Menu.status_counts(socket.assigns.today))
    |> stream(:items, items, reset: true)
  end

  @impl true
  def handle_event("category", %{"category" => name}, socket) do
    case Enum.find(socket.assigns.categories, &(&1.name == name)) do
      nil ->
        {:noreply, socket}

      category ->
        {:noreply,
         socket
         |> assign(:search, "")
         |> assign(:search_form, to_form(%{"q" => ""}, as: :search))
         |> push_patch(to: ~p"/menu?#{[category: category.id]}")}
    end
  end

  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    {:noreply,
     socket
     |> assign(:search, q)
     |> assign(:search_form, to_form(%{"q" => q}, as: :search))
     |> load_items()}
  end

  def handle_event("toggle_sold_out", %{"id" => id}, socket) do
    socket = assign(socket, :today, Menu.today())
    item = Menu.get_item!(id)
    sold_out? = not Menu.sold_out?(item, socket.assigns.today)
    {:noreply, socket |> set_sold_out(item, sold_out?) |> toast_sold_out(item, sold_out?)}
  end

  def handle_event("undo_sold_out", _params, socket) do
    case socket.assigns.toast do
      %{meta: %{id: id, sold_out: sold_out?}} ->
        item = Menu.get_item!(id)

        {:noreply,
         socket
         |> assign(:today, Menu.today())
         |> set_sold_out(item, sold_out?)
         |> Toast.clear()}

      _ ->
        {:noreply, socket}
    end
  end

  defp set_sold_out(socket, item, sold_out?) do
    {:ok, item} = Menu.set_sold_out(item, sold_out?, socket.assigns.today)

    socket
    |> assign(:status, Menu.status_counts(socket.assigns.today))
    |> stream_insert(:items, item)
  end

  defp toast_sold_out(socket, item, true) do
    Toast.put(socket, "#{item.name} หมดวันนี้ · เปิดใหม่พรุ่งนี้",
      action: "ยกเลิก",
      on_action: "undo_sold_out",
      meta: %{id: item.id, sold_out: false}
    )
  end

  defp toast_sold_out(socket, item, false) do
    Toast.put(socket, "#{item.name} เปิดขายแล้ว",
      action: "ยกเลิก",
      on_action: "undo_sold_out",
      meta: %{id: item.id, sold_out: true}
    )
  end

  # ---------------------------------------------------------------- render

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} bare>
      <UI.screen id="menu-manage" padded={false} class="pb-[72px] md:pb-0 md:pl-24 lg:pl-56">
        <:top>
          <header class="flex flex-wrap items-center gap-x-2.5 gap-y-2.5 px-4 pt-3.5 pb-2 md:flex-nowrap md:gap-4 md:px-6 md:pt-5 md:pb-3 lg:px-8">
            <div class="flex flex-1 flex-col md:flex-none">
              <h1 class="text-[22px] leading-tight font-bold">จัดการเมนู</h1>
              <p id="menu-status" class="text-[14px] text-muted">
                เปิดขาย {@status.on_sale} · หมดวันนี้ {@status.sold_out}
              </p>
            </div>
            <.link
              id="add-item"
              navigate={~p"/menu/new?#{new_item_query(@category)}"}
              class={[
                "inline-flex h-11 flex-none items-center justify-center rounded-md bg-primary px-3.5 md:order-last",
                "text-[15px] font-bold text-white transition-[background-color,transform] duration-150",
                "hover:bg-primary-hover active:scale-[0.98]"
              ]}
            >
              + เพิ่มเมนู
            </.link>
            <.form
              for={@search_form}
              id="menu-search"
              phx-change="search"
              class="relative w-full md:ml-auto md:w-auto md:max-w-md md:flex-1"
            >
              <.icon
                name="hero-magnifying-glass"
                class="pointer-events-none absolute top-1/2 left-3 size-5 -translate-y-1/2 text-icon"
              />
              <input
                type="search"
                id="menu-search-q"
                name={@search_form[:q].name}
                value={@search_form[:q].value}
                placeholder="ค้นหาเมนู"
                aria-label="ค้นหาเมนู"
                autocomplete="off"
                phx-debounce="200"
                class={[
                  "h-11 w-full rounded-md border-[1.5px] border-line bg-surface pr-3.5 pl-10 text-[15px] text-primary",
                  "outline-none transition-colors duration-150 placeholder:text-icon",
                  "focus:border-2 focus:border-primary focus:bg-white"
                ]}
              />
            </.form>
          </header>
          <.category_tabs
            id="menu-tabs"
            class="md:px-6 lg:px-8"
            categories={Enum.map(@categories, & &1.name)}
            active={@search == "" && @category && @category.name}
            on_select="category"
          />
        </:top>

        <div class="flex items-baseline justify-between pt-1">
          <span id="menu-list-title" class="text-[14px] font-bold text-muted">
            {list_title(@search, @category)} {@item_count} เมนู
          </span>
          <span class="text-[13px] text-muted">สวิตช์ = เปิดขาย / หมดวันนี้</span>
        </div>

        <div
          id="menu-items"
          phx-update="stream"
          class="grid grid-cols-1 gap-2 md:grid-cols-2 md:gap-3 xl:grid-cols-3 2xl:grid-cols-4"
        >
          <.item_row
            :for={{dom_id, item} <- @streams.items}
            id={dom_id}
            item={item}
            sold_out={Menu.sold_out?(item, @today)}
          />
          <div
            id="menu-items-empty"
            class="col-span-full hidden rounded-lg border-[1.5px] border-dashed border-line-dashed px-4 py-8 text-center text-[14px] text-muted only:block"
          >
            {if @search == "", do: "ยังไม่มีเมนูในหมวดนี้", else: "ไม่พบเมนูที่ค้นหา"}
          </div>
        </div>

        <UI.hint class="mt-1">
          ปิดสวิตช์ = เมนูขึ้นเทาในหน้ารับออเดอร์ กดสั่งไม่ได้ · เปิดใหม่อัตโนมัติพรุ่งนี้ · แตะชื่อเมนู = แก้ไข
        </UI.hint>
      </UI.screen>

      <.main_nav current={:menu} role={@current_role} />
      <.app_toast toast={@toast} />
    </Layouts.app>
    """
  end

  defp new_item_query(nil), do: []
  defp new_item_query(category), do: [category: category.id]

  defp list_title("", nil), do: "เมนู"
  defp list_title("", category), do: category.name
  defp list_title(search, _category), do: "ผลค้นหา “#{String.trim(search)}”"

  attr :id, :string, required: true
  attr :item, :map, required: true
  attr :sold_out, :boolean, required: true

  defp item_row(assigns) do
    ~H"""
    <div
      id={@id}
      data-sold-out={@sold_out}
      class={[
        "flex min-h-16 items-center gap-1.5 rounded-lg border-[1.5px] border-line-soft py-1 pr-1.5 pl-3.5",
        "transition-colors duration-200",
        if(@sold_out, do: "bg-soldout", else: "bg-surface")
      ]}
    >
      <.link
        id={"#{@id}-edit"}
        navigate={~p"/menu/#{@item.id}/edit"}
        class={[
          "group flex min-w-0 flex-1 items-center gap-1.5 py-1.5 text-primary",
          @sold_out && "opacity-60"
        ]}
      >
        <span class="flex min-w-0 flex-1 flex-col leading-[1.3]">
          <span class="flex flex-wrap items-center gap-1.5 text-[16px] font-bold">
            {@item.name}
            <.menu_tag :if={@sold_out} kind={:soldout} />
          </span>
          <span class="truncate text-[13px] text-muted">{item_subtitle(@item)}</span>
        </span>
        <.icon
          name="hero-chevron-right"
          class="size-5 flex-none text-icon transition-transform duration-150 group-hover:translate-x-0.5"
        />
      </.link>
      <UI.switch
        id={"#{@id}-switch"}
        touch
        checked={!@sold_out}
        aria-label={"#{@item.name} เปิดขาย"}
        phx-click="toggle_sold_out"
        phx-value-id={@item.id}
      />
    </div>
    """
  end

  defp item_subtitle(item) do
    groups =
      item.item_option_groups
      |> Enum.map(& &1.option_group)
      |> Enum.map_join(", ", fn %OptionGroup{name: name} -> name end)

    [Menu.price_summary(item), groups]
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" · ")
  end
end
