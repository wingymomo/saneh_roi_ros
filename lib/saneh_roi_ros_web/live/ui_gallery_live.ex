defmodule SanehRoiRosWeb.UIGalleryLive do
  @moduledoc """
  Interactive gallery of every `SanehRoiRosUI` component and state.

  Mounted at `/dev/ui` when `config :saneh_roi_ros, ui_gallery: true`
  (dev and test only).
  """
  use SanehRoiRosWeb, :live_view

  alias SanehRoiRosWeb.QuickAdd

  on_mount SanehRoiRosWeb.Toast
  on_mount QuickAdd
  on_mount SanehRoiRosWeb.MainNav

  @demo_nav_items [
    %{key: :home, label: "หน้าแรก", icon: "hero-home", path: "/dev/ui"},
    %{key: :orders, label: "ออเดอร์", icon: "hero-clipboard-document-list", path: "/dev/ui"},
    %{key: :reports, label: "รายงาน", icon: "hero-chart-bar", path: "/dev/ui", disabled: true}
  ]

  @noodles ~w(เส้นเล็ก เส้นใหญ่ เส้นหมี่ขาว บะหมี่ มาม่า วุ้นเส้น)
  @no_add ~w(ผัก ผักโรย ถั่ว ถั่วงอก)
  @brews [{"ชาไทย", "thai-tea"}, {"กาแฟ", "coffee"}, {"ชาเขียวนม", "green-tea"}]
  @sodas [
    %{id: "coke", name: "โค้ก", prices: [glass_bottle: 15, can: 16, cup: 25]},
    %{id: "sprite", name: "สไปรท์", prices: [glass_bottle: nil, can: 16, cup: 25]}
  ]
  @size_labels %{glass_bottle: "ขวดแก้ว", can: "กระป๋อง", cup: "แก้วใหญ่"}
  @staff [
    %{id: "1", name: "นิด", role: :staff},
    %{id: "2", name: "เมย์", role: :manager},
    %{id: "3", name: "เจ้าของร้าน", role: :owner}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "UI kit")
     |> assign(:noodles, @noodles)
     |> assign(:no_add_options, @no_add)
     |> assign(:brews, @brews)
     |> assign(:sodas, @sodas)
     |> assign(:staff, @staff)
     |> assign(:demo_nav_items, @demo_nav_items)
     |> assign(:noodle, "เส้นเล็ก")
     |> assign(:no_add, MapSet.new())
     |> assign(:cone, "ถ้วย")
     |> assign(:role, :staff)
     |> assign(:category, "ก๋วยเตี๋ยว")
     |> assign(:counts, %{
       "thai-tea-bottle" => 0,
       "thai-tea-glass" => 2,
       "eggs" => 3,
       "bowls" => 1,
       "summary" => 1,
       "tally-zero" => 0,
       "tally-count" => 2,
       "tally-label" => 0
     })
     |> QuickAdd.put_counts(%{"coke-can" => 2})
     |> assign(:switches, %{
       "bag" => false,
       "kitchen" => true,
       "soldout" => false,
       "touch" => true
     })
     |> assign(:selected_staff, "1")
     |> assign(:pin, "")
     |> assign(:toast_ms, 4000)
     |> assign(:form, to_form(%{"customer" => "พี่แดง"}, as: :takeaway))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    toast_ms =
      case Integer.parse(params["toast_ms"] || "") do
        {ms, ""} when ms >= 0 -> ms
        _ -> 4000
      end

    {:noreply, assign(socket, :toast_ms, toast_ms)}
  end

  @impl true
  def handle_event("noodle", %{"value" => noodle}, socket) do
    {:noreply, assign(socket, :noodle, noodle)}
  end

  def handle_event("no_add", %{"value" => item}, socket) do
    set = socket.assigns.no_add
    set = if MapSet.member?(set, item), do: MapSet.delete(set, item), else: MapSet.put(set, item)
    {:noreply, assign(socket, :no_add, set)}
  end

  def handle_event("cone", %{"value" => value}, socket),
    do: {:noreply, assign(socket, :cone, value)}

  def handle_event("role", %{"value" => value}, socket),
    do: {:noreply, assign(socket, :role, String.to_existing_atom(value))}

  def handle_event("category", %{"category" => category}, socket),
    do: {:noreply, assign(socket, :category, category)}

  def handle_event("step", %{"key" => key, "delta" => delta}, socket) do
    counts =
      Map.update(socket.assigns.counts, key, 0, &max(&1 + String.to_integer(delta), 0))

    {:noreply, assign(socket, :counts, counts)}
  end

  def handle_event("toggle", %{"switch" => name}, socket) do
    {:noreply, update(socket, :switches, &Map.update!(&1, name, fn v -> !v end))}
  end

  def handle_event("pick_staff", %{"id" => id}, socket) do
    {:noreply, socket |> assign(:selected_staff, id) |> assign(:pin, "")}
  end

  def handle_event("digit", %{"digit" => digit}, socket) do
    pin = socket.assigns.pin
    {:noreply, assign(socket, :pin, if(String.length(pin) < 4, do: pin <> digit, else: pin))}
  end

  def handle_event("backspace", _params, socket) do
    {:noreply, update(socket, :pin, &String.slice(&1, 0..-2//1))}
  end

  def handle_event("random_pin", _params, socket) do
    {:noreply, assign(socket, :pin, "4826")}
  end

  def handle_event("validate", %{"takeaway" => params}, socket) do
    errors =
      if String.trim(params["customer"] || "") == "", do: [customer: {"กรุณาใส่ชื่อ", []}], else: []

    {:noreply,
     assign(socket, :form, to_form(params, as: :takeaway, errors: errors, action: :validate))}
  end

  def handle_event("noop", _params, socket), do: {:noreply, socket}

  defp order_total(ordered, sodas) do
    prices =
      for soda <- sodas, {size, price} <- soda.prices, price, into: %{} do
        {"#{soda.id}-#{size}", price}
      end

    Enum.reduce(ordered, 0, fn {sku, n}, acc -> acc + n * Map.get(prices, sku, 0) end)
  end

  defp size_label(size), do: Map.fetch!(@size_labels, size)

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :code, :string, required: true
  attr :note, :string, default: nil
  slot :inner_block, required: true

  defp spec(assigns) do
    ~H"""
    <section id={@id} class="flex flex-col gap-3">
      <h2 class="m-0 text-[20px] font-bold text-primary">
        {@title}<code class="ml-2 text-[14px] font-medium text-muted">{@code}</code>
      </h2>
      <p :if={@note} class="m-0 text-[14px] leading-normal text-muted">{@note}</p>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr :id, :string, required: true
  attr :title, :string, required: true
  attr :module, :string, required: true
  attr :path, :string, required: true
  slot :inner_block, required: true

  defp group_header(assigns) do
    ~H"""
    <header id={@id} class="flex scroll-mt-24 flex-col gap-1.5 border-t-2 border-primary pt-6">
      <h2 class="m-0 text-[24px] font-bold">
        {@title}<code class="ml-2 text-[15px] font-semibold text-muted">{@module}</code>
      </h2>
      <p class="m-0 text-[14px] text-muted">{render_slot(@inner_block)}</p>
      <code class="text-[13px] text-icon">{@path}</code>
    </header>
    """
  end

  attr :id, :string, required: true
  attr :name, :string, required: true
  attr :code, :string, required: true
  attr :usage, :string, required: true
  slot :inner_block, required: true

  defp variant_row(assigns) do
    ~H"""
    <div
      id={@id}
      class="flex flex-col gap-3 rounded-xl border border-dashed border-line bg-bg p-4 sm:flex-row sm:items-center"
    >
      <div class="flex flex-col gap-0.5 sm:w-52 sm:flex-none">
        <b class="text-[16px]">{@name}</b>
        <code class="text-[13px] text-muted">{@code}</code>
        <span class="text-[13px] text-muted">{@usage}</span>
      </div>
      <div class="flex flex-1 flex-wrap items-center gap-3">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  attr :class, :any, default: nil
  slot :inner_block, required: true

  defp demo(assigns) do
    ~H"""
    <div class={[
      "flex flex-wrap items-center gap-3.5 rounded-xl border border-dashed border-line bg-bg p-5",
      @class
    ]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div id="ui-gallery" class="flex flex-col gap-9 pb-24 font-sans text-primary">
        <div class="flex flex-col gap-2">
          <h1 class="m-0 text-[28px] font-bold">Components — แอปพนักงาน เสน่ห์ร้อยรส</h1>
          <p class="m-0 text-muted">
            state ดูจาก <code>aria-pressed</code>, <code>aria-checked</code>,
            <code>aria-disabled</code>
          </p>
          <nav id="gallery-toc" class="flex flex-wrap gap-2 text-[14px] font-semibold">
            <a href="#group-web" class="underline underline-offset-4">App components</a>
            <span class="text-muted">·</span>
            <a href="#group-ui" class="underline underline-offset-4">UI kit</a>
          </nav>
        </div>

        <.group_header
          id="group-web"
          title="App components"
          module="SanehRoiRosWeb"
          path="lib/saneh_roi_ros_web/components"
        >
          มี logic ของแอป (หมวดเมนู, เพิ่มแล้วขึ้น toast ให้ยกเลิก) · เรียกด้วย <code>&lt;.name&gt;</code>
        </.group_header>

        <.spec
          id="spec-tabs"
          title="Category tabs"
          code="<.category_tabs>"
          note="ลำดับตายตัว 7 แท็บ · scroll ลงเกิน ~40px กลายเป็นแถวเดียว sticky ปัดได้"
        >
          <p id="active-category" class="m-0 text-[14px] text-muted">แท็บที่เลือก: {@category}</p>
        </.spec>
        <%!-- direct child of the tall page column so it can stay sticky while scrolling --%>
        <.category_tabs id="tabs" active={@category} on_select="category" class="-mt-6" />

        <.spec
          id="spec-quick-add"
          title="Quick add (app)"
          code="<.quick_add_button> <.app_toast>"
          note="SanehRoiRosWeb.QuickAdd: แตะ = +1 แล้วขึ้น toast ให้กดยกเลิก · ใช้กับน้ำอัดลม / น้ำเปล่า / ขนมถุง"
        >
          <.demo class="max-w-[390px] flex-col items-stretch gap-0">
            <UI.price_row :for={soda <- @sodas} name={soda.name}>
              <%= for {size, price} <- soda.prices do %>
                <UI.cell_empty :if={is_nil(price)} />
                <.quick_add_button
                  :if={price}
                  id={"soda-#{soda.id}-#{size}"}
                  sku={"#{soda.id}-#{size}"}
                  label={"#{soda.name} #{size_label(size)}"}
                  price={price}
                  counts={@quick_add_counts}
                />
              <% end %>
            </UI.price_row>
          </.demo>
        </.spec>

        <.spec
          id="spec-option-group"
          title="Option group row"
          code="<.option_group_row selection=…>"
          note="ป้ายข้างชื่อกลุ่มคือ <.menu_tag kind={selection}>"
        >
          <div id="option-group-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-group-required"
              name="Required"
              code="selection={:required}"
              usage="ต้องเลือก 1 · เช่น เส้น"
            >
              <.option_group_row
                id="group-noodle"
                class="w-full"
                name="เส้น"
                selection={:required}
                options={@noodles}
                phx-click="noop"
              />
            </.variant_row>
            <.variant_row
              id="variant-group-single"
              name="Single (optional)"
              code="selection={:single}"
              usage="เลือก 1 ไม่บังคับ · เช่น ขนาด"
            >
              <.option_group_row
                id="group-size"
                class="w-full"
                name="ขนาด"
                selection={:single}
                options={["ธรรมดา", "พิเศษ"]}
                phx-click="noop"
              />
            </.variant_row>
            <.variant_row
              id="variant-group-multi"
              name="Multi"
              code="selection={:multi}"
              usage="เลือกได้หลายอย่าง · เช่น ไม่ใส่"
            >
              <.option_group_row
                id="group-no-add"
                class="w-full"
                name="ไม่ใส่"
                selection={:multi}
                options={Enum.map(@no_add_options, &"ไม่ใส่#{&1}")}
                phx-click="noop"
              />
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-tables"
          title="Table tile"
          code="<.table_tile>"
          note="ว่าง / มีลูกค้า (pill แสดงคิวทุกรอบ) · ไม่มีสถานะ กำลังทำ"
        >
          <.demo class="max-w-[390px] flex-col items-stretch">
            <.table_grid id="tables">
              <.table_tile id="table-1" number={1} queues={[3, 7]} phx-click="noop" />
              <.table_tile id="table-2" number={2} phx-click="noop" />
              <.table_tile id="table-3" number={3} queues={[5]} phx-click="noop" />
            </.table_grid>
          </.demo>
        </.spec>

        <.spec
          id="spec-menu-tag"
          title="Menu tag"
          code="<.menu_tag kind=…>"
          note="SanehRoiRosWeb.MenuTag · kind กำหนดทั้งข้อความและสี (ใช้ UI.tag ข้างใน)"
        >
          <div id="menu-tag-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-menu-required"
              name="Required"
              code="kind={:required}"
              usage="กลุ่มตัวเลือกที่ต้องเลือก 1 · tag :soft"
            >
              <.menu_tag id="menu-tag-required" kind={:required} />
            </.variant_row>
            <.variant_row
              id="variant-menu-single"
              name="Single"
              code="kind={:single}"
              usage="เลือก 1 ไม่บังคับ · tag :soft"
            >
              <.menu_tag id="menu-tag-single" kind={:single} />
            </.variant_row>
            <.variant_row
              id="variant-menu-multi"
              name="Multi"
              code="kind={:multi}"
              usage="เลือกได้หลายอย่าง · tag :neutral"
            >
              <.menu_tag id="menu-tag-multi" kind={:multi} />
            </.variant_row>
            <.variant_row
              id="variant-menu-soldout"
              name="Sold out"
              code="kind={:soldout}"
              usage="เมนูหมดวันนี้ · tag :accent"
            >
              <.menu_tag id="menu-tag-soldout" kind={:soldout} />
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-role-tag"
          title="Role tag"
          code="<.role_tag role=…>"
          note="SanehRoiRosWeb.RoleTag · ใช้ UI.tag ข้างใน"
        >
          <div id="role-tag-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-role-staff"
              name="Staff"
              code="role={:staff}"
              usage="พนักงาน · tag :soft"
            >
              <.role_tag id="role-staff" role={:staff} />
            </.variant_row>
            <.variant_row
              id="variant-role-manager"
              name="Manager"
              code="role={:manager}"
              usage="ผู้จัดการ · tag :sand"
            >
              <.role_tag id="role-manager" role={:manager} />
            </.variant_row>
            <.variant_row
              id="variant-role-owner"
              name="Owner"
              code="role={:owner}"
              usage="เจ้าของ · tag :primary"
            >
              <.role_tag id="role-owner" role={:owner} />
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-main-nav"
          title="Main nav"
          code="<.main_nav role current>"
          note="SanehRoiRosWeb.MainNav · สิทธิ์ตามตำแหน่ง · แตะเมนูสีเทาแล้วขึ้น toast เอง (หน้าไม่ต้องเขียน handler)"
        >
          <div id="main-nav-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-nav-staff"
              name="Staff"
              code="role={:staff}"
              usage="เปิดได้แค่ รับออเดอร์"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <.main_nav id="nav-staff" current={:orders} role={:staff} position={:absolute} />
              </div>
            </.variant_row>
            <.variant_row
              id="variant-nav-manager"
              name="Manager"
              code="role={:manager}"
              usage="เพิ่ม จัดการเมนู"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <.main_nav id="nav-manager" current={:menu} role={:manager} position={:absolute} />
              </div>
            </.variant_row>
            <.variant_row
              id="variant-nav-owner"
              name="Owner"
              code="role={:owner}"
              usage="เปิดได้ทุกเมนู"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <.main_nav id="nav-owner" current={:sales} role={:owner} position={:absolute} />
              </div>
            </.variant_row>
            <.variant_row
              id="variant-nav-try"
              name="Try it"
              code="role={@role}"
              usage="เปลี่ยนตำแหน่ง แล้วแตะเมนูสีเทา"
            >
              <div class="flex w-full flex-col gap-2">
                <UI.segment
                  id="nav-role"
                  options={[{"staff", "พนักงาน"}, {"manager", "ผู้จัดการ"}, {"owner", "เจ้าของ"}]}
                  value={@role}
                  on_select="role"
                />
                <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                  <.main_nav id="nav" current={:orders} role={@role} position={:absolute} />
                </div>
              </div>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-order-bar"
          title="Order bar"
          code="<.order_bar count total>"
          note="SanehRoiRosWeb.OrderBar · แถบสรุปลอย · เนื้อหาต้องเว้นล่าง ≥ 110px"
        >
          <div id="order-bar-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-order-bar-live"
              name="Default"
              code="count total"
              usage="ยังไม่ส่งครัว · ตัวเลขตาม Quick add"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <.order_bar
                  id="order-bar"
                  count={QuickAdd.total_count(@quick_add_counts)}
                  total={order_total(@quick_add_counts, @sodas)}
                  position={:absolute}
                  phx-click="noop"
                />
              </div>
            </.variant_row>
            <.variant_row
              id="variant-order-bar-custom"
              name="Custom text"
              code="caption cta"
              usage="เปลี่ยนข้อความได้ เช่น หน้ากลับบ้าน"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <.order_bar
                  id="order-bar-custom"
                  count={5}
                  total={1250}
                  caption="กลับบ้าน · ก3"
                  cta="คิดเงิน →"
                  position={:absolute}
                  phx-click="noop"
                />
              </div>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-login"
          title="Login: name tile · PIN · keypad"
          code="<.name_tile> <.pin_dots> <.keypad>"
        >
          <.demo class="max-w-[390px] flex-col items-stretch">
            <div class="grid grid-cols-3 gap-2.5">
              <.name_tile
                :for={s <- @staff}
                id={"staff-#{s.id}"}
                name={s.name}
                role={s.role}
                selected={s.id == @selected_staff}
                phx-click="pick_staff"
                phx-value-id={s.id}
              />
            </div>
            <.pin_dots id="pin" filled={String.length(@pin)} />
            <.keypad id="keypad" on_digit="digit" on_backspace="backspace" on_extra="random_pin">
              <:extra>สุ่มให้</:extra>
            </.keypad>
          </.demo>
        </.spec>

        <.spec
          id="spec-button-row"
          title="Button row"
          code="<.button_row>"
          note="footer 2 ปุ่ม: secondary (flex 1) + primary (flex 2)"
        >
          <.demo class="max-w-[390px] flex-col items-stretch">
            <.button_row id="btn-row">
              <:secondary id="btn-row-cancel">ยกเลิก</:secondary>
              <:primary id="btn-row-save">บันทึก · เพิ่ม ฝน</:primary>
            </.button_row>
          </.demo>
        </.spec>

        <.group_header
          id="group-ui"
          title="UI kit"
          module="SanehRoiRosUI"
          path="lib/saneh_roi_ros_ui"
        >
          ไม่มี logic ของแอป · state อยู่ที่ LiveView · เรียกด้วย <code>&lt;UI.name&gt;</code>
        </.group_header>

        <.spec
          id="spec-button"
          title="Button"
          code="<UI.button variant=…>"
          note="primary 56px · secondary/dashed/danger 52px · sm 40px"
        >
          <div id="button-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-primary"
              name="Primary"
              code="variant={:primary}"
              usage="ปุ่มหลักของหน้า (footer) · 56px · บอกผลลัพธ์ + ยอด"
            >
              <UI.button id="btn-primary" variant={:primary} phx-click="noop">
                ส่งครัว + คิดเงิน · 220
              </UI.button>
            </.variant_row>
            <.variant_row
              id="variant-secondary"
              name="Secondary"
              code="variant={:secondary}"
              usage="ทางเลือกรอง / ยกเลิก · 52px · ค่าเริ่มต้น"
            >
              <UI.button id="btn-secondary" variant={:secondary}>ส่งครัวก่อน</UI.button>
            </.variant_row>
            <.variant_row
              id="variant-dashed"
              name="Dashed"
              code="variant={:dashed}"
              usage="เพิ่มรายการใหม่ เช่น “+ เพิ่มตัวเลือก” · 52px"
            >
              <UI.button id="btn-dashed" variant={:dashed}>+ เพิ่มตัวเลือก</UI.button>
            </.variant_row>
            <.variant_row
              id="variant-danger"
              name="Danger"
              code="variant={:danger}"
              usage="ลบ / เอาออก · 52px"
            >
              <UI.button id="btn-danger" variant={:danger}>เอาออกจากเมนูนี้</UI.button>
            </.variant_row>
            <.variant_row
              id="variant-sm"
              name="Small"
              code="size={:sm}"
              usage="action ใน top bar · 40px · ใช้กับทุก variant"
            >
              <UI.button id="btn-sm" size={:sm}>ย้ายโต๊ะ</UI.button>
              <UI.button id="btn-sm-primary" size={:sm} variant={:primary}>+ สั่งเพิ่ม</UI.button>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-chip"
          title="Chip"
          code="<UI.chip selected>"
          note="เลือก 1 = radio · เลือกได้หลายอย่าง = toggle"
        >
          <div id="chip-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-chip-off"
              name="Unselected"
              code="selected={false}"
              usage="พื้น surface ขอบ border · aria-pressed=false"
            >
              <UI.chip id="chip-off">เส้นใหญ่</UI.chip>
            </.variant_row>
            <.variant_row
              id="variant-chip-on"
              name="Selected"
              code="selected"
              usage="พื้น primary ตัวขาว · aria-pressed=true"
            >
              <UI.chip id="chip-on" selected>เส้นเล็ก</UI.chip>
            </.variant_row>
            <.variant_row
              id="variant-chip-disabled"
              name="Disabled"
              code="disabled"
              usage="เลือกไม่ได้ เช่น ของหมด"
            >
              <UI.chip id="chip-disabled" disabled>วุ้นเส้น</UI.chip>
            </.variant_row>
            <.variant_row
              id="variant-chip-single"
              name="Single choice"
              code="<UI.chips> + selected={x == @value}"
              usage="กลุ่ม เลือก 1 · ทำงานแบบ radio"
            >
              <UI.chips id="noodle-chips">
                <UI.chip
                  :for={{n, i} <- Enum.with_index(@noodles)}
                  id={"noodle-#{i}"}
                  selected={n == @noodle}
                  phx-click="noodle"
                  value={n}
                >
                  {n}
                </UI.chip>
              </UI.chips>
            </.variant_row>
            <.variant_row
              id="variant-chip-multi"
              name="Multi choice"
              code="<UI.chips> + selected={x in @set}"
              usage="กลุ่ม เลือกได้หลายอย่าง · ทำงานแบบ toggle"
            >
              <UI.chips id="no-add-chips">
                <UI.chip
                  :for={{n, i} <- Enum.with_index(@no_add_options)}
                  id={"no-add-#{i}"}
                  selected={MapSet.member?(@no_add, n)}
                  phx-click="no_add"
                  value={n}
                >
                  ไม่ใส่{n}
                </UI.chip>
              </UI.chips>
            </.variant_row>
          </div>
        </.spec>

        <.spec id="spec-segment" title="Segment" code="<UI.segment>">
          <.demo class="max-w-[390px] flex-col items-stretch">
            <UI.segment id="cone" options={["ถ้วย", "โคน"]} value={@cone} on_select="cone" />
          </.demo>
        </.spec>

        <.spec
          id="spec-stepper"
          title="Stepper"
          code="<UI.stepper value min=0>"
          note="ค่า 0 = ปุ่ม − จาง · มากกว่า 0 = active · size sm ใช้ในหน้าสรุป"
        >
          <div id="stepper-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-step-empty"
              name="Empty"
              code="value={0}"
              usage="ยังไม่สั่ง · ปุ่ม − จาง (aria-disabled) กดไม่ได้"
            >
              <UI.stepper
                id="step-bottle"
                label="ชาไทย ขวด"
                value={@counts["thai-tea-bottle"]}
                on_change="step"
                params={%{key: "thai-tea-bottle"}}
              />
            </.variant_row>
            <.variant_row
              id="variant-step-active"
              name="Active"
              code="value={2}"
              usage="สั่งแล้ว · ขอบ primary · ลดจนเหลือ 0 = ยกเลิก"
            >
              <UI.stepper
                id="step-glass"
                label="ชาไทย แก้ว"
                value={@counts["thai-tea-glass"]}
                on_change="step"
                params={%{key: "thai-tea-glass"}}
              />
            </.variant_row>
            <.variant_row
              id="variant-step-min"
              name="Min"
              code="min={1}"
              usage="ค่าต่ำสุดไม่ใช่ 0 เช่น จำนวนชาม · ถึง min แล้วปุ่ม − กดไม่ได้"
            >
              <UI.stepper
                id="step-bowls"
                label="จำนวนชาม"
                value={@counts["bowls"]}
                min={1}
                on_change="step"
                params={%{key: "bowls"}}
              />
            </.variant_row>
            <.variant_row
              id="variant-step-max"
              name="Max"
              code="max={3}"
              usage="ถึงค่าสูงสุด · ปุ่ม + กดไม่ได้"
            >
              <UI.stepper
                id="step-eggs"
                label="ไข่"
                value={@counts["eggs"]}
                max={3}
                on_change="step"
                params={%{key: "eggs"}}
              />
            </.variant_row>
            <.variant_row
              id="variant-step-sm"
              name="Small"
              code="size={:sm}"
              usage="ใช้ในหน้าสรุปออเดอร์ · 36px"
            >
              <UI.stepper
                id="step-summary"
                size={:sm}
                value={@counts["summary"]}
                on_change="step"
                params={%{key: "summary"}}
              />
            </.variant_row>
          </div>
          <h3 class="m-0 mt-2 text-[16px] font-bold">ในตารางราคา (น้ำชง)</h3>
          <.demo class="max-w-[390px] flex-col items-stretch gap-0">
            <UI.price_row>
              <UI.col_head label="ขวด" price={20} />
              <UI.col_head label="แก้ว" price={25} />
            </UI.price_row>
            <UI.price_row :for={{name, id} <- @brews} name={name}>
              <UI.stepper
                id={"brew-#{id}-bottle"}
                value={Map.get(@counts, "#{id}-bottle", 0)}
                on_change="step"
                params={%{key: "#{id}-bottle"}}
              />
              <UI.stepper
                id={"brew-#{id}-glass"}
                value={Map.get(@counts, "#{id}-glass", 0)}
                on_change="step"
                params={%{key: "#{id}-glass"}}
              />
            </UI.price_row>
          </.demo>
        </.spec>

        <.spec
          id="spec-tally"
          title="Tally button"
          code="<UI.tally_button price count>"
          note="ปุ่มนับอย่างเดียว: แตะ = +1 ต่อไปเรื่อยๆ · ไม่มี toast (ดู Quick add)"
        >
          <div id="tally-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-tally-zero"
              name="No count"
              code="count={0}"
              usage="ยังไม่สั่ง · แตะเพื่อเริ่มนับ"
            >
              <UI.tally_button
                id="tally-zero"
                price={15}
                count={@counts["tally-zero"]}
                phx-click="step"
                phx-value-key="tally-zero"
                phx-value-delta="1"
              />
            </.variant_row>
            <.variant_row
              id="variant-tally-count"
              name="Counting"
              code="count={2}"
              usage="สั่งแล้ว · ขอบ primary + badge จำนวน · แตะต่อ = +1"
            >
              <UI.tally_button
                id="tally-count"
                price={16}
                count={@counts["tally-count"]}
                phx-click="step"
                phx-value-key="tally-count"
                phx-value-delta="1"
              />
            </.variant_row>
            <.variant_row
              id="variant-tally-label"
              name="With label"
              code={~s(label="ขวด")}
              usage="ป้ายขนาดเหนือราคา"
            >
              <UI.tally_button
                id="tally-label"
                label="ขวด"
                price={20}
                count={@counts["tally-label"]}
                phx-click="step"
                phx-value-key="tally-label"
                phx-value-delta="1"
              />
            </.variant_row>
            <.variant_row
              id="variant-tally-empty"
              name="Empty cell"
              code="<UI.cell_empty />"
              usage="ไม่มีขนาดนี้ · ไม่ใช่ปุ่ม"
            >
              <UI.cell_empty />
            </.variant_row>
          </div>
        </.spec>

        <.spec id="spec-switch" title="Switch" code="<UI.switch checked>">
          <.demo class="max-w-[390px] flex-col items-stretch">
            <UI.switch_row
              id="switch-bag"
              title="ใส่ถุงกลับบ้าน"
              subtitle="ชามนี้"
              checked={@switches["bag"]}
              phx-click="toggle"
              phx-value-switch="bag"
            />
            <UI.switch_row
              id="switch-kitchen"
              title="พิมพ์ลงใบครัว"
              subtitle="ปิดได้ถ้าหยิบหน้าร้านเอง"
              checked={@switches["kitchen"]}
              phx-click="toggle"
              phx-value-switch="kitchen"
            />
            <div class="flex items-center gap-1.5 rounded-lg border-[1.5px] border-line-soft bg-surface py-1 pr-1.5 pl-3.5">
              <span class="flex-1 text-[16px] font-bold">touch · 64×44 tap target</span>
              <UI.switch
                id="switch-touch"
                touch
                checked={@switches["touch"]}
                aria-label="touch switch"
                phx-click="toggle"
                phx-value-switch="touch"
              />
            </div>
          </.demo>
        </.spec>

        <.spec
          id="spec-list"
          title="List"
          code="<UI.list>"
          note="กล่องรวมแถว · เส้นคั่น divider ระหว่างแถวอัตโนมัติ"
        >
          <div id="list-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-list-many"
              name="Grouped rows"
              code="<UI.list> + หลาย <UI.list_row>"
              usage="เมนูตั้งค่า / รายชื่อ · มีเส้นคั่นระหว่างแถว"
            >
              <UI.list id="staff-list" class="w-full">
                <UI.list_row
                  id="row-staff"
                  title="รายชื่อพนักงาน"
                  subtitle="ใช้งาน 4 คน · ปิดใช้งาน 1"
                  phx-click="noop"
                >
                  <:icon><UI.icon name="hero-users" class="size-5" /></:icon>
                </UI.list_row>
                <UI.list_row
                  id="row-add-staff"
                  title="เพิ่มพนักงาน"
                  subtitle="ชื่อเล่น · ตำแหน่ง · รหัส 4 หลัก"
                  phx-click="noop"
                >
                  <:icon><UI.icon name="hero-plus" class="size-5" /></:icon>
                </UI.list_row>
              </UI.list>
            </.variant_row>
            <.variant_row
              id="variant-list-one"
              name="Single row"
              code="<UI.list> + 1 <UI.list_row>"
              usage="ไม่มีเส้นคั่น"
            >
              <UI.list id="single-list" class="w-full">
                <UI.list_row
                  id="row-printer"
                  title="เครื่องพิมพ์"
                  subtitle="เชื่อมต่อแล้ว"
                  phx-click="noop"
                />
              </UI.list>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-section-label"
          title="Section label"
          code="<UI.section_label>"
          note="หัวกลุ่มเล็ก 13/700 สี muted"
        >
          <div id="section-label-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-section-label-alone"
              name="Alone"
              code="<UI.section_label>"
              usage="ป้ายหัวกลุ่ม"
            >
              <UI.section_label id="section-label-alone">จัดการพนักงาน</UI.section_label>
            </.variant_row>
            <.variant_row
              id="variant-section-label-list"
              name="Above a list"
              code="<UI.section_label> + <UI.list>"
              usage="ใช้คู่กับ list ในหน้าตั้งค่า"
            >
              <div class="flex w-full flex-col gap-2">
                <UI.section_label>ร้าน</UI.section_label>
                <UI.list>
                  <UI.list_row
                    id="row-tables"
                    title="โต๊ะ"
                    subtitle="15 โต๊ะ"
                    phx-click="noop"
                  />
                  <UI.list_row
                    id="row-queue"
                    title="เลขคิว"
                    subtitle="เริ่มใหม่ทุกวัน"
                    phx-click="noop"
                  />
                </UI.list>
              </div>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-list-row"
          title="List row"
          code="<UI.list_row>"
          note="สูงอย่างน้อย 64 · ชื่อ 16/700 + บรรทัดรอง 13"
        >
          <div id="list-row-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-row-button"
              name="Button"
              code="phx-click=…"
              usage="แถวกดได้ · มีลูกศร ›"
            >
              <UI.list class="w-full">
                <UI.list_row
                  id="row-button"
                  title="เครื่องพิมพ์"
                  subtitle="ใบครัว 58mm"
                  phx-click="noop"
                />
              </UI.list>
            </.variant_row>
            <.variant_row
              id="variant-row-link"
              name="Link"
              code="navigate={…}"
              usage="ไปหน้าอื่น · มีลูกศร ›"
            >
              <UI.list class="w-full">
                <UI.list_row
                  id="row-link"
                  title="ตั้งค่า"
                  subtitle="เปิดหน้าตั้งค่า"
                  navigate="/dev/ui"
                />
              </UI.list>
            </.variant_row>
            <.variant_row
              id="variant-row-icon"
              name="With icon"
              code="<:icon>"
              usage="ไอคอนพื้น primary-tint ด้านซ้าย"
            >
              <UI.list class="w-full">
                <UI.list_row
                  id="row-icon"
                  title="รายชื่อพนักงาน"
                  subtitle="ใช้งาน 4 คน"
                  phx-click="noop"
                >
                  <:icon><UI.icon name="hero-users" class="size-5" /></:icon>
                </UI.list_row>
              </UI.list>
            </.variant_row>
            <.variant_row
              id="variant-row-soldout"
              name="Sold out + trailing"
              code="soldout <:badge> <:trailing>"
              usage="แถวเมนูที่ปิดขาย · ปุ่มด้านขวา (แถวเป็น div ไม่ใช่ปุ่ม)"
            >
              <UI.list class="w-full">
                <UI.list_row
                  id="row-soldout"
                  title="เย็นตาโฟต้มยำ"
                  subtitle="50 / 60 · ทะเล 90 / 130"
                  soldout={!@switches["soldout"]}
                >
                  <:badge :if={!@switches["soldout"]}>
                    <.menu_tag kind={:soldout} />
                  </:badge>
                  <:trailing>
                    <UI.switch
                      id="switch-soldout"
                      checked={@switches["soldout"]}
                      aria-label="เปิดขาย"
                      phx-click="toggle"
                      phx-value-switch="soldout"
                    />
                  </:trailing>
                </UI.list_row>
              </UI.list>
            </.variant_row>
            <.variant_row
              id="variant-row-plain"
              name="Plain"
              code="(no click / link)"
              usage="แสดงข้อมูลอย่างเดียว · ไม่มีลูกศร"
            >
              <UI.list class="w-full">
                <UI.list_row id="row-plain" title="เวอร์ชัน" subtitle="0.1.0" />
              </UI.list>
            </.variant_row>
          </div>
        </.spec>

        <.spec id="spec-card" title="Card" code="<UI.card variant=…>">
          <div id="card-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-card-base"
              name="Base"
              code="variant={:base}"
              usage="การ์ดทั่วไป · พื้น surface"
            >
              <UI.card id="card-base" class="w-full">
                <b class="text-[16px]">น้ำตก</b>
                <span class="text-[14px] text-muted">เส้นใหญ่ · หมูสับ · ธรรมดา</span>
              </UI.card>
            </.variant_row>
            <.variant_row
              id="variant-card-elevated"
              name="Elevated"
              code="variant={:elevated}"
              usage="การ์ดสรุปออเดอร์ · พื้นขาว"
            >
              <UI.card id="card-elevated" variant={:elevated} class="w-full">
                <b class="text-[16px]">น้ำตก</b>
                <span class="text-[14px] text-muted">เส้นใหญ่ · หมูสับ · ธรรมดา</span>
                <UI.note_tag>หมายเหตุ: แยกน้ำ</UI.note_tag>
              </UI.card>
            </.variant_row>
            <.variant_row
              id="variant-card-highlighted"
              name="Highlighted"
              code="variant={:highlighted}"
              usage="มีของสั่งแล้ว · ขอบ 2px primary"
            >
              <UI.card id="card-highlighted" variant={:highlighted} class="w-full">
                <b class="text-[16px]">ชามที่ 1</b>
                <span class="text-[14px] text-muted">เส้นเล็ก · หมูตุ๋น · พิเศษ</span>
              </UI.card>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-tag"
          title="Tag"
          code="<UI.tag variant=…>"
          note="variant เป็นแค่หน้าตา · ความหมายมาจากฝั่งแอป"
        >
          <div id="tag-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-tag-primary"
              name="Primary"
              code="variant={:primary}"
              usage="พื้น primary ตัวขาว · เช่น เจ้าของ"
            >
              <UI.tag id="tag-primary" variant={:primary}>เจ้าของ</UI.tag>
            </.variant_row>
            <.variant_row
              id="variant-tag-soft"
              name="Soft"
              code="variant={:soft}"
              usage="พื้น primary-tint · เช่น ต้องเลือก 1, พนักงาน (ค่าเริ่มต้น)"
            >
              <UI.tag id="tag-soft" variant={:soft}>ต้องเลือก 1</UI.tag>
            </.variant_row>
            <.variant_row
              id="variant-tag-neutral"
              name="Neutral"
              code="variant={:neutral}"
              usage="พื้นเบจ · เช่น เลือกได้หลายอย่าง"
            >
              <UI.tag id="tag-neutral" variant={:neutral}>เลือกได้หลายอย่าง</UI.tag>
            </.variant_row>
            <.variant_row
              id="variant-tag-sand"
              name="Sand"
              code="variant={:sand}"
              usage="พื้น sand ตัวน้ำตาล · เช่น ผู้จัดการ"
            >
              <UI.tag id="tag-sand" variant={:sand}>ผู้จัดการ</UI.tag>
            </.variant_row>
            <.variant_row
              id="variant-tag-accent"
              name="Accent"
              code="variant={:accent}"
              usage="พื้นน้ำตาล ตัวขาว · เช่น หมดวันนี้"
            >
              <UI.tag id="tag-accent" variant={:accent}>หมดวันนี้</UI.tag>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-bottom-nav"
          title="Bottom nav"
          code="<UI.bottom_nav items current on_disabled>"
          note="แถบล่าง · รายการกับสิทธิ์มาจากฝั่งแอป (ดู Main nav)"
        >
          <div id="bottom-nav-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-ui-nav-current"
              name="Current"
              code="current={:orders}"
              usage="รายการที่อยู่ตอนนี้ตัวหนาสี primary"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.bottom_nav
                  id="ui-nav-current"
                  items={Enum.map(@demo_nav_items, &Map.delete(&1, :disabled))}
                  current={:orders}
                  position={:absolute}
                />
              </div>
            </.variant_row>
            <.variant_row
              id="variant-ui-nav-disabled"
              name="Disabled item"
              code="%{disabled: true}"
              usage="สีเทา aria-disabled ไม่มีกุญแจ · แตะแล้วส่ง on_disabled"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.bottom_nav
                  id="ui-nav-disabled"
                  items={@demo_nav_items}
                  current={:home}
                  position={:absolute}
                />
              </div>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-toast"
          title="Toast"
          code="<UI.toast>"
          note="หายเองใน ~4 วิ (ตัวอย่างนี้ค้างไว้ด้วย duration={0}) · แตะปุ่มใน Quick add เพื่อดูของจริง"
        >
          <div id="toast-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-toast-action"
              name="With action"
              code="action on_action"
              usage="ยืนยันการเพิ่ม + ปุ่มยกเลิก (undo)"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.toast
                  id="toast-demo-action"
                  duration={0}
                  position={:absolute}
                  action="ยกเลิก"
                  class="!bottom-5"
                >
                  เพิ่ม ชาไทย แก้ว แล้ว (รวม 2)
                </UI.toast>
              </div>
            </.variant_row>
            <.variant_row
              id="variant-toast-plain"
              name="Message only"
              code="(no action)"
              usage="แจ้งเตือน เช่น ไม่มีสิทธิ์"
            >
              <div class="relative h-[88px] w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.toast id="toast-demo-plain" duration={0} position={:absolute} class="!bottom-5">
                  ยอดขาย เปิดได้เฉพาะเจ้าของร้าน
                </UI.toast>
              </div>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-input"
          title="Input"
          code="<UI.input>"
          note="สูง 48 · label ด้านบน · hint ด้านล่าง · ใช้กับ form field ได้"
        >
          <div id="input-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-input-field"
              name="Form field"
              code="field={@form[:customer]}"
              usage="label + hint · พิมพ์ว่างแล้วขึ้น error"
            >
              <.form for={@form} id="takeaway-form" phx-change="validate" class="w-full">
                <UI.input
                  field={@form[:customer]}
                  label="ชื่อลูกค้า (เรียกตอนของเสร็จ)"
                  hint="ไม่บังคับ"
                />
              </.form>
            </.variant_row>
            <.variant_row
              id="variant-input-error"
              name="Error"
              code="errors={[…]}"
              usage="ขอบสี danger · ข้อความแทน hint"
            >
              <UI.input
                id="input-error"
                name="pin"
                label="รหัส 4 หลัก"
                value="12"
                errors={["ต้องเป็นตัวเลข 4 หลัก"]}
                class="w-full"
              />
            </.variant_row>
            <.variant_row
              id="variant-input-select"
              name="Select"
              code={~s(type="select")}
              usage="เลือกจากรายการ"
            >
              <UI.input
                id="input-select"
                name="role"
                type="select"
                label="ตำแหน่ง"
                value="staff"
                options={[{"พนักงาน", "staff"}, {"ผู้จัดการ", "manager"}]}
                class="w-full"
              />
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-hint"
          title="Hint"
          code="<UI.hint>"
          note="กล่องคำแนะนำ พื้น sand"
        >
          <.demo class="max-w-[390px] flex-col items-stretch">
            <UI.hint id="hint-demo">ถามลูกค้าให้ครบก่อนแล้วค่อยกดส่ง จะได้ออกใบครัวใบเดียว</UI.hint>
          </.demo>
        </.spec>

        <.spec
          id="spec-top-bar"
          title="Top bar"
          code="<UI.top_bar>"
          note="ปุ่มกลับ 44×44 · ชื่อหน้า · action ด้านขวา"
        >
          <div id="top-bar-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-top-bar-full"
              name="Back + actions"
              code="back <:actions>"
              usage="หน้าย่อย เช่น โต๊ะ 1 · ย้ายโต๊ะ"
            >
              <div class="w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.top_bar
                  id="top-bar"
                  title="โต๊ะ 1"
                  subtitle="รอบที่ 2 · คิว #3"
                  back="/dev/ui"
                >
                  <:actions><UI.button size={:sm}>ย้ายโต๊ะ</UI.button></:actions>
                </UI.top_bar>
              </div>
            </.variant_row>
            <.variant_row
              id="variant-top-bar-plain"
              name="Title only"
              code="size={:lg}"
              usage="หน้าแรก เช่น รับออเดอร์ · ไม่มีปุ่มกลับ"
            >
              <div class="w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.top_bar id="top-bar-plain" title="รับออเดอร์" size={:lg} />
              </div>
            </.variant_row>
            <.variant_row
              id="variant-top-bar-back"
              name="Back + subtitle"
              code="back subtitle size={:md}"
              usage="หน้าฟอร์ม เช่น เพิ่มพนักงาน"
            >
              <div class="w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.top_bar
                  id="top-bar-back"
                  title="เพิ่มพนักงาน"
                  subtitle="ชื่อเล่น · ตำแหน่ง · รหัส"
                  size={:md}
                  back="/dev/ui"
                />
              </div>
            </.variant_row>
          </div>
        </.spec>

        <.spec
          id="spec-footer"
          title="Footer"
          code="<UI.footer_bar>"
          note="ติดล่าง (sticky) · ใส่ปุ่มหลักของหน้า"
        >
          <div id="footer-variants" class="flex flex-col gap-3">
            <.variant_row
              id="variant-footer-total"
              name="With total"
              code="total={60}"
              usage="หน้าตัวเลือก · แถว รวม … บาท + ปุ่มหลัก"
            >
              <div class="w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.footer_bar id="footer" total={60} class="!static">
                  <UI.button variant={:primary} block>เสร็จ · 60</UI.button>
                </UI.footer_bar>
              </div>
            </.variant_row>
            <.variant_row
              id="variant-footer-row"
              name="With button row"
              code="<.button_row>"
              usage="สองปุ่ม เช่น ยกเลิก + บันทึก"
            >
              <div class="w-full overflow-hidden rounded-lg border border-dashed border-line bg-bg">
                <UI.footer_bar id="footer-row" class="!static">
                  <.button_row>
                    <:secondary>ยกเลิก</:secondary>
                    <:primary>บันทึก</:primary>
                  </.button_row>
                </UI.footer_bar>
              </div>
            </.variant_row>
          </div>
        </.spec>
      </div>

      <.app_toast toast={@toast} duration={@toast_ms} />
    </Layouts.app>
    """
  end
end
