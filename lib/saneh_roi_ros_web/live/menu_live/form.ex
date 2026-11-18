defmodule SanehRoiRosWeb.MenuLive.Form do
  @moduledoc """
  เพิ่มเมนู / แก้ไขเมนู (1, 1b–1f) and its option-group screens (2, 2b).

  One LiveView holds the whole flow so unsaved input survives while the
  manager edits option groups. The sub-screen is chosen with the `group`
  query param (patched, so the browser back button works):

    * none — the item form
    * `group=pick` — choose an existing option group or create one
    * `group=new` / `group=<id>` — edit an option group (2 / 2b)

  Option groups are shared between items, so "เสร็จ" saves the group right
  away; the item itself (sizes, attached groups, …) is saved with
  "บันทึกเมนู".
  """
  use SanehRoiRosWeb, :live_view

  alias SanehRoiRos.Menu
  alias SanehRoiRos.Menu.{Item, Option, OptionGroup}

  @drinks "เครื่องดื่ม"

  @impl true
  def mount(params, _session, socket) do
    categories = Menu.list_categories()

    item =
      case socket.assigns.live_action do
        :edit -> Menu.get_item!(params["id"])
        :new -> Menu.new_item(default_category_id(categories, params["category"]))
      end

    attached = Enum.map(item.item_option_groups, & &1.option_group)

    {:ok,
     socket
     |> assign(:page_title, if(item.id, do: "แก้ไขเมนู", else: "เพิ่มเมนู"))
     |> assign(:categories, categories)
     |> assign(:item, item)
     |> assign(:base_path, base_path(item))
     |> assign(:groups, Map.new(attached, &{&1.id, &1}))
     |> assign(:attached_ids, Enum.map(attached, & &1.id))
     |> assign_item_form(Menu.change_item(item))}
  end

  defp default_category_id([], _), do: nil

  defp default_category_id([first | _] = categories, id) do
    Enum.find(categories, first, &(to_string(&1.id) == id)).id
  end

  defp base_path(%Item{id: nil}), do: ~p"/menu/new"
  defp base_path(%Item{id: id}), do: ~p"/menu/#{id}/edit"

  @impl true
  def handle_params(params, _uri, socket) do
    {:noreply, apply_screen(socket, params["group"])}
  end

  defp apply_screen(socket, nil), do: assign(socket, :screen, :item)

  defp apply_screen(socket, "pick") do
    attached = MapSet.new(socket.assigns.attached_ids)
    available = Enum.reject(Menu.list_option_groups(), &MapSet.member?(attached, &1.id))

    socket
    |> assign(:screen, :pick)
    |> assign(:available_groups, available)
  end

  defp apply_screen(socket, "new") do
    group = Menu.new_option_group()

    socket
    |> assign(:screen, :group)
    |> assign(:group, group)
    |> assign(:group_usage, 0)
    |> assign_group_form(
      Menu.change_option_group(group, %{"options" => %{"0" => %{"name" => ""}}})
    )
  end

  defp apply_screen(socket, id) do
    group = Menu.get_option_group!(id)

    socket
    |> assign(:screen, :group)
    |> assign(:group, group)
    |> assign(:group_usage, Menu.option_group_usage(group))
    |> assign_group_form(Menu.change_option_group(group))
  end

  defp assign_item_form(socket, changeset) do
    socket
    |> assign(:item_changeset, changeset)
    |> assign(:form, to_form(changeset, as: :item))
  end

  defp assign_group_form(socket, changeset) do
    assign(socket, :group_form, to_form(changeset, as: :group))
  end

  # ---------------------------------------------------------------- item events

  @impl true
  def handle_event("validate", %{"item" => params}, socket) do
    changeset =
      socket.assigns.item
      |> Menu.change_item(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_item_form(socket, changeset)}
  end

  def handle_event("save", %{"item" => params}, socket) do
    params = Map.put(params, "option_group_ids", socket.assigns.attached_ids)

    result =
      case socket.assigns.item do
        %Item{id: nil} -> Menu.create_item(params)
        item -> Menu.update_item(item, params)
      end

    case result do
      {:ok, item} ->
        {:noreply,
         socket
         |> put_flash(:info, "บันทึก #{item.name} แล้ว")
         |> push_navigate(to: ~p"/menu?#{[category: item.category_id]}")}

      {:error, changeset} ->
        {:noreply, assign_item_form(socket, changeset)}
    end
  end

  def handle_event("attach_group", %{"id" => id}, socket) do
    group = Menu.get_option_group!(id)

    {:noreply,
     socket
     |> attach(group)
     |> push_patch(to: socket.assigns.base_path)}
  end

  # ---------------------------------------------------------------- group events

  def handle_event("validate_group", %{"group" => params}, socket) do
    changeset =
      socket.assigns.group
      |> Menu.change_option_group(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_group_form(socket, changeset)}
  end

  def handle_event("save_group", %{"group" => params}, socket) do
    case Menu.save_option_group(socket.assigns.group, params) do
      {:ok, group} ->
        {:noreply,
         socket
         |> attach(group)
         |> push_patch(to: socket.assigns.base_path)}

      {:error, changeset} ->
        {:noreply, assign_group_form(socket, changeset)}
    end
  end

  def handle_event("detach_group", _params, socket) do
    id = socket.assigns.group.id

    {:noreply,
     socket
     |> assign(:attached_ids, List.delete(socket.assigns.attached_ids, id))
     |> push_patch(to: socket.assigns.base_path)}
  end

  defp attach(socket, %OptionGroup{id: id} = group) do
    ids = socket.assigns.attached_ids

    socket
    |> assign(:groups, Map.put(socket.assigns.groups, id, group))
    |> assign(:attached_ids, if(id in ids, do: ids, else: ids ++ [id]))
  end

  # ---------------------------------------------------------------- render

  @impl true
  def render(%{screen: :pick} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} bare>
      <.scroll_top_hook />
      <UI.screen
        id="group-picker"
        padded={false}
        class={nav_offset()}
        content_class={item_column()}
        phx-hook=".ScrollTop"
      >
        <:top>
          <UI.top_bar
            title="เพิ่มตัวเลือก"
            size={:md}
            back={@base_path}
            back_patch
            class="border-b border-line-soft pb-2"
            inner_class={item_column()}
          />
        </:top>
        <div class="flex flex-col gap-2.5 pt-2">
          <div class="flex flex-col gap-0.5">
            <span class="text-[14px] font-semibold">ใช้ชุดที่มีอยู่แล้ว</span>
            <span class="text-[13px] text-muted">แตะเพื่อเพิ่มให้เมนูนี้ · ชุดเดียวกันใช้ได้หลายเมนู</span>
          </div>
          <div class="grid grid-cols-1 items-start gap-2.5 md:grid-cols-2 md:gap-3">
            <.option_group_row
              :for={group <- @available_groups}
              id={"pick-group-#{group.id}"}
              name={group.name}
              selection={OptionGroup.selection(group)}
              options={option_labels(group.options)}
              phx-click="attach_group"
              phx-value-id={group.id}
            />
          </div>
          <p
            :if={@available_groups == []}
            id="pick-group-empty"
            class="rounded-lg bg-sand px-3.5 py-3 text-[14px] text-note"
          >
            ยังไม่มีชุดตัวเลือกอื่น
          </p>
          <UI.button
            id="new-group"
            variant={:dashed}
            block
            patch={"#{@base_path}?group=new"}
            class="mt-1"
          >
            + สร้างชุดตัวเลือกใหม่
          </UI.button>
        </div>
      </UI.screen>
      <.desktop_nav role={@current_role} toast={@toast} />
    </Layouts.app>
    """
  end

  def render(%{screen: :group} = assigns) do
    ~H"""
    <Layouts.app flash={@flash} bare>
      <.scroll_top_hook />
      <UI.screen
        id="group-editor"
        padded={false}
        class={nav_offset()}
        content_class={group_column()}
        phx-hook=".ScrollTop"
      >
        <:top>
          <UI.top_bar
            title="ตัวเลือก"
            size={:md}
            back={@base_path}
            back_patch
            class="border-b border-line-soft pb-2"
            inner_class={group_column()}
          />
        </:top>

        <.form
          for={@group_form}
          id="group-form"
          phx-change="validate_group"
          phx-submit="save_group"
          class="flex flex-col gap-7 pt-3 pb-4"
        >
          <UI.input
            field={@group_form[:name]}
            label="ชื่อตัวเลือก"
            placeholder="เช่น เส้น, ไม่ใส่"
          />

          <div class="flex flex-col gap-2.5">
            <span class="text-[14px] font-semibold">ลูกค้าเลือกได้</span>
            <.radio_segment
              id="group-multi"
              field={@group_form[:multi]}
              options={[{"false", "1 อย่าง"}, {"true", "หลายอย่าง"}]}
            />
            <.switch_field
              id="group-required"
              field={@group_form[:required]}
              title="ต้องเลือกก่อนสั่ง"
              subtitle={multi?(@group_form) && "ปิดไว้ = ไม่เลือกเลยก็สั่งได้"}
            />
            <UI.input
              :if={multi?(@group_form)}
              field={@group_form[:max_select]}
              type="number"
              label="เลือกได้สูงสุด"
              hint="เว้นว่าง = ไม่จำกัด · กันพนักงานกดเกิน"
              placeholder="ไม่จำกัด"
              min="1"
              inputmode="numeric"
            />
          </div>

          <div class="flex flex-col gap-2.5">
            <div class="flex items-baseline justify-between">
              <span class="text-[14px] font-semibold">ตัวเลือก</span>
              <span class="text-[13px] text-muted">บวกราคา (บาท)</span>
            </div>
            <div class="overflow-hidden rounded-xl border-[1.5px] border-line-soft bg-surface">
              <div id="group-options" class="[&>*]:border-b [&>*]:border-divider">
                <.inputs_for :let={of} field={@group_form[:options]}>
                  <div id={"option-row-#{of.index}"} class="flex items-start gap-2.5 py-2 pr-2 pl-3">
                    <input type="hidden" name="group[options_sort][]" value={of.index} />
                    <.row_input
                      field={of[:name]}
                      aria-label="ชื่อตัวเลือก"
                      placeholder="พิมพ์ชื่อตัวเลือก…"
                      class="flex-1"
                      phx-mounted={of.index > 0 && new_blank_row?(of) && JS.focus()}
                    />
                    <.row_input
                      field={of[:price_text]}
                      value={price_text_value(of)}
                      aria-label={"บวกราคา #{of[:name].value}"}
                      inputmode="decimal"
                      placeholder="0"
                      class="w-[88px] text-right"
                      input_class="text-right font-semibold"
                    />
                    <button
                      id={"option-row-#{of.index}-drop"}
                      type="button"
                      name="group[options_drop][]"
                      value={of.index}
                      phx-click={JS.dispatch("change")}
                      aria-label={"ลบ #{of[:name].value}"}
                      class="flex size-11 flex-none cursor-pointer items-center justify-center rounded-sm text-icon transition-colors hover:bg-white hover:text-danger"
                    >
                      <.icon name="hero-x-mark" class="size-[18px]" />
                    </button>
                  </div>
                </.inputs_for>
              </div>
              <input type="hidden" name="group[options_drop][]" />
              <button
                id="add-option"
                type="button"
                name="group[options_sort][]"
                value="new"
                phx-click={JS.dispatch("change")}
                class="h-12 w-full cursor-pointer px-4 text-left text-[15px] font-semibold text-primary transition-colors hover:bg-white"
              >
                + เพิ่มตัวเลือก
              </button>
            </div>
            <p
              :for={msg <- errors(@group_form[:options])}
              class="text-[13px] font-semibold text-danger"
            >
              {msg}
            </p>
            <p class="text-[13px] leading-normal text-muted">
              ราคาต่างกันตามขนาด ใส่คั่นด้วย / ตามลำดับขนาด เช่น ทะเล 40 / 70
            </p>
          </div>

          <UI.hint :if={@group_usage > 1} id="group-shared-hint">
            ชุดนี้ใช้ร่วมกับเมนูอื่น ({@group_usage} เมนู) ถ้าแก้ตรงนี้ ทุกเมนูที่ใช้ชุดนี้จะเปลี่ยนตามด้วย
          </UI.hint>
        </.form>

        <:bottom>
          <UI.footer_bar inner_class={group_column()}>
            <div class="flex gap-2.5 md:justify-end">
              <UI.button
                :if={@group.id && @group.id in @attached_ids}
                id="detach-group"
                variant={:danger}
                phx-click="detach_group"
                class="flex-1 px-3 whitespace-nowrap md:flex-none md:px-5"
              >
                เอาออกจากเมนูนี้
              </UI.button>
              <UI.button
                id="save-group"
                type="submit"
                form="group-form"
                variant={:primary}
                phx-disable-with="กำลังบันทึก…"
                class="flex-1 md:w-44 md:flex-none"
              >
                เสร็จ
              </UI.button>
            </div>
          </UI.footer_bar>
        </:bottom>
      </UI.screen>
      <.desktop_nav role={@current_role} toast={@toast} />
    </Layouts.app>
    """
  end

  def render(assigns) do
    assigns = assign(assigns, :preview, build_preview(assigns))

    ~H"""
    <Layouts.app flash={@flash} bare>
      <.scroll_top_hook />
      <UI.screen
        id="menu-form"
        padded={false}
        class={nav_offset()}
        content_class={item_column()}
      >
        <:top>
          <UI.top_bar
            title={@page_title}
            size={:md}
            back={~p"/menu?#{back_query(@form)}"}
            class="border-b border-line-soft pb-2"
            inner_class={item_column()}
          />
        </:top>

        <.form
          for={@form}
          id="item-form"
          phx-change="validate"
          phx-submit="save"
          class="grid grid-cols-1 gap-7 pt-3 pb-4 lg:grid-cols-[minmax(0,1fr)_360px] lg:items-start lg:gap-10 lg:pt-5"
        >
          <div class="flex min-w-0 flex-col gap-7">
            <UI.input
              field={@form[:category_id]}
              type="select"
              label="หมวด"
              options={Enum.map(@categories, &{&1.name, &1.id})}
            />

            <div :if={drinks?(@form, @categories)} class="flex flex-col gap-1.5">
              <span class="text-[14px] font-semibold">กลุ่ม</span>
              <.radio_chips
                id="item-drink-group"
                field={@form[:drink_group]}
                options={Item.drink_groups()}
              />
              <small class="text-[13px] text-muted">กลุ่มบอกว่าเมนูไปอยู่ส่วนไหนในแท็บเครื่องดื่ม</small>
            </div>

            <div class="grid grid-cols-1 items-start gap-7 md:grid-cols-2 md:gap-4">
              <UI.input
                field={@form[:name]}
                label="ชื่อเมนู"
                placeholder="เช่น น้ำตก"
              />

              <UI.input
                field={@form[:short_names]}
                label="ชื่อย่อ (ใช้ค้นหาตอนรับออเดอร์)"
                hint="คั่นด้วยจุลภาค · ไม่บังคับ"
                class="[&_input]:font-normal [&_input]:text-[16px]"
              />
            </div>

            <div class="flex flex-col gap-2.5">
              <div class="flex items-baseline justify-between">
                <span class="text-[14px] font-semibold">ขนาดและราคา</span>
                <span class="text-[13px] text-muted">ชื่อขนาด · ราคา (บาท)</span>
              </div>
              <div class="overflow-hidden rounded-xl border-[1.5px] border-line-soft bg-surface">
                <div id="item-variants" class="[&>*]:border-b [&>*]:border-divider">
                  <.inputs_for :let={vf} field={@form[:price_variants]}>
                    <div
                      id={"variant-row-#{vf.index}"}
                      class="flex items-start gap-2.5 py-2 pr-2 pl-3"
                    >
                      <input type="hidden" name="item[variants_sort][]" value={vf.index} />
                      <.row_input
                        field={vf[:name]}
                        aria-label="ชื่อขนาด"
                        placeholder="เช่น ธรรมดา"
                        class="flex-1"
                        phx-mounted={vf.index > 0 && new_blank_row?(vf) && JS.focus()}
                      />
                      <.row_input
                        field={vf[:price]}
                        type="number"
                        aria-label={"ราคา #{vf[:name].value}"}
                        inputmode="numeric"
                        min="0"
                        placeholder="0"
                        class="w-[88px]"
                        input_class="text-right text-[17px] font-semibold border-line"
                      />
                      <button
                        :if={vf.index > 0}
                        id={"variant-row-#{vf.index}-drop"}
                        type="button"
                        name="item[variants_drop][]"
                        value={vf.index}
                        phx-click={JS.dispatch("change")}
                        aria-label={"ลบขนาด #{vf[:name].value}"}
                        class="flex size-11 flex-none cursor-pointer items-center justify-center rounded-sm text-icon transition-colors hover:bg-white hover:text-danger"
                      >
                        <.icon name="hero-x-mark" class="size-[18px]" />
                      </button>
                      <span :if={vf.index == 0} class="w-11 flex-none" />
                    </div>
                  </.inputs_for>
                </div>
                <input type="hidden" name="item[variants_drop][]" />
                <button
                  id="add-variant"
                  type="button"
                  name="item[variants_sort][]"
                  value="new"
                  phx-click={JS.dispatch("change")}
                  class="h-12 w-full cursor-pointer px-4 text-left text-[15px] font-semibold text-primary transition-colors hover:bg-white"
                >
                  + เพิ่มขนาด
                </button>
              </div>
              <p
                :for={msg <- errors(@form[:price_variants])}
                class="text-[13px] font-semibold text-danger"
              >
                {msg}
              </p>
              <p class="text-[13px] leading-normal text-muted">
                ชื่อขนาดจะเป็นราคาก็ได้ หรือเป็น เล็ก/กลาง/ใหญ่ ก็ได้ · มีราคาเดียวก็ลบแถวอื่นออก
              </p>
            </div>

            <div class="flex flex-col gap-2.5">
              <div class="flex flex-col gap-0.5">
                <span class="text-[14px] font-semibold">ตัวเลือกตอนสั่ง</span>
                <span class="text-[13px] text-muted">สิ่งที่พนักงานต้องถามลูกค้า แตะเพื่อแก้</span>
              </div>
              <div id="item-groups" class="flex flex-col gap-2.5">
                <.option_group_row
                  :for={group <- attached_groups(assigns)}
                  id={"item-group-#{group.id}"}
                  name={group.name}
                  selection={OptionGroup.selection(group)}
                  options={option_labels(group.options)}
                  patch={"#{@base_path}?group=#{group.id}"}
                />
              </div>
              <.link
                :if={@attached_ids == []}
                id="add-group"
                patch={"#{@base_path}?group=pick"}
                class="rounded-lg border-[1.5px] border-dashed border-line-dashed bg-surface p-3.5 text-center text-[14px] text-muted transition-colors hover:bg-white"
              >
                ไม่มี · <span class="font-semibold text-primary underline">+ เพิ่มตัวเลือก</span>
              </.link>
              <UI.button
                :if={@attached_ids != []}
                id="add-group"
                variant={:dashed}
                block
                patch={"#{@base_path}?group=pick"}
              >
                + เพิ่มตัวเลือก
              </UI.button>
            </div>

            <.switch_field
              id="item-print"
              field={@form[:print_to_kitchen]}
              title="พิมพ์ลงใบครัว"
              subtitle={
                if(checked?(@form[:print_to_kitchen]),
                  do: "ปิดได้ถ้าพนักงานหน้าร้านหยิบหรือชงเอง",
                  else: "ปิดไว้ · ไม่ขึ้นใบครัว แต่ยังขึ้นบิลและใบเสร็จ"
                )
              }
            />
          </div>

          <aside class="min-w-0 lg:sticky lg:top-5">
            <.preview preview={@preview} />
          </aside>
        </.form>

        <:bottom>
          <UI.footer_bar inner_class={item_column()}>
            <div class="flex gap-2.5 md:justify-end">
              <UI.button id="cancel-item" navigate={~p"/menu?#{back_query(@form)}"} class="px-[18px]">
                ยกเลิก
              </UI.button>
              <UI.button
                id="save-item"
                type="submit"
                form="item-form"
                variant={:primary}
                phx-disable-with="กำลังบันทึก…"
                class="flex-1 md:w-44 md:flex-none"
              >
                บันทึกเมนู
              </UI.button>
            </div>
          </UI.footer_bar>
        </:bottom>
      </UI.screen>
      <.desktop_nav role={@current_role} toast={@toast} />
    </Layouts.app>
    """
  end

  # ---------------------------------------------------------------- form pieces

  # Page widths on larger screens. The item form has two columns; an option
  # group is one short list, so it stays narrower.
  defp item_column, do: "mx-auto w-full max-w-6xl"
  defp group_column, do: "mx-auto w-full max-w-2xl"
  defp nav_offset, do: "md:pl-24 lg:pl-56"

  attr :role, :atom, required: true
  attr :toast, :map, default: nil

  # Phones give these focused screens the full height, with no bottom bar.
  defp desktop_nav(assigns) do
    ~H"""
    <.main_nav current={:menu} role={@role} class="max-md:hidden" />
    <.app_toast toast={@toast} />
    """
  end

  # The option-group screens start at the top of the page instead of keeping
  # the item form's scroll position. (Returning to the item form keeps the
  # browser's position, so the manager lands back near the option groups.)
  defp scroll_top_hook(assigns) do
    ~H"""
    <script :type={Phoenix.LiveView.ColocatedHook} name=".ScrollTop">
      export default {
        mounted() { window.scrollTo(0, 0) }
      }
    </script>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true
  attr :type, :string, default: "text"
  attr :value, :any, default: nil
  attr :class, :any, default: nil
  attr :input_class, :any, default: nil
  attr :rest, :global, include: ~w(placeholder inputmode min phx-mounted)

  # Compact 44px input used inside the size / option rows, with its error below.
  defp row_input(assigns) do
    errors = if used_input?(assigns.field), do: errors(assigns.field), else: []
    assigns = assign(assigns, :errors, errors)

    ~H"""
    <div class={["flex min-w-0 flex-col gap-1", @class]}>
      <input
        type={@type}
        id={@field.id}
        name={@field.name}
        value={@value || Phoenix.HTML.Form.normalize_value(@type, @field.value)}
        aria-invalid={@errors != [] && "true"}
        class={[
          "h-11 w-full min-w-0 rounded-sm border-[1.5px] bg-white px-3 text-[16px] text-primary outline-none",
          "transition-colors duration-150 placeholder:font-normal placeholder:text-icon",
          "focus:border-2 focus:border-primary focus:px-[11.5px]",
          if(@errors == [], do: "border-line-soft", else: "border-danger"),
          @input_class
        ]}
        {@rest}
      />
      <small :for={msg <- @errors} class="text-[12px] font-semibold text-danger">{msg}</small>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :field, Phoenix.HTML.FormField, required: true
  attr :title, :string, required: true
  attr :subtitle, :any, default: nil

  # Switch-styled checkbox inside the form (no extra events needed).
  defp switch_field(assigns) do
    assigns = assign(assigns, :checked, checked?(assigns.field))

    ~H"""
    <label
      for={@id}
      class="flex cursor-pointer items-center gap-3 rounded-xl border-[1.5px] border-line-soft bg-surface py-3 pr-3 pl-4"
    >
      <span class="flex flex-1 flex-col gap-0.5">
        <b class="text-[16px]">{@title}</b>
        <small :if={@subtitle} class="text-[13px] text-muted">{@subtitle}</small>
      </span>
      <input type="hidden" name={@field.name} value="false" />
      <input
        type="checkbox"
        id={@id}
        name={@field.name}
        value="true"
        checked={@checked}
        role="switch"
        class="peer sr-only"
      />
      <span
        aria-hidden="true"
        class={[
          "flex h-[30px] w-[52px] flex-none items-center rounded-full p-[3px] transition-colors duration-200",
          "peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-primary",
          if(@checked, do: "bg-primary", else: "bg-switch-off")
        ]}
      >
        <span class={[
          "block size-6 rounded-full bg-white shadow-sm transition-transform duration-200",
          @checked && "translate-x-[22px]"
        ]} />
      </span>
    </label>
    """
  end

  attr :id, :string, required: true
  attr :field, Phoenix.HTML.FormField, required: true
  attr :options, :list, required: true

  # Segment-styled radio group (2 / 2b: "1 อย่าง | หลายอย่าง").
  defp radio_segment(assigns) do
    ~H"""
    <div
      id={@id}
      role="radiogroup"
      class="grid auto-cols-fr grid-flow-col gap-1 rounded-lg bg-sand p-1"
    >
      <label
        :for={{value, label} <- @options}
        class={[
          "flex h-11 cursor-pointer items-center justify-center rounded-sm text-[17px] transition-colors duration-150",
          "has-focus-visible:outline-2 has-focus-visible:outline-primary",
          if(to_string(@field.value) == value,
            do: "bg-primary font-bold text-white",
            else: "text-muted hover:text-primary"
          )
        ]}
      >
        <input
          type="radio"
          id={"#{@id}-#{value}"}
          name={@field.name}
          value={value}
          checked={to_string(@field.value) == value}
          class="sr-only"
        />
        {label}
      </label>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :field, Phoenix.HTML.FormField, required: true
  attr :options, :list, required: true

  # Chip-styled radio group (drink group: น้ำชง / น้ำอัดลม / น้ำเปล่า).
  defp radio_chips(assigns) do
    ~H"""
    <div id={@id} role="radiogroup" class="grid grid-cols-3 gap-2">
      <label
        :for={{option, index} <- Enum.with_index(@options)}
        class={[
          "flex h-11 cursor-pointer items-center justify-center rounded-md border-[1.5px] text-[15px]",
          "transition-colors duration-150 has-focus-visible:outline-2 has-focus-visible:outline-primary",
          if(@field.value == option,
            do: "border-primary bg-primary font-semibold text-white",
            else: "border-line bg-surface text-primary hover:bg-white"
          )
        ]}
      >
        <input
          type="radio"
          id={"#{@id}-#{index}"}
          name={@field.name}
          value={option}
          checked={@field.value == option}
          class="sr-only"
        />
        {option}
      </label>
    </div>
    """
  end

  # ---------------------------------------------------------------- preview

  attr :preview, :map, required: true

  # "ตัวอย่าง (หน้ารับออเดอร์)": roughly how the item looks when ordering.
  defp preview(%{preview: %{style: :price_buttons}} = assigns) do
    ~H"""
    <div id="item-preview" class="flex flex-col gap-2.5">
      <span class="text-[14px] font-semibold">ตัวอย่าง (หน้ารับออเดอร์)</span>
      <div class="flex items-center gap-2 rounded-xl border-[1.5px] border-line-soft bg-white p-3.5">
        <span class="min-w-0 flex-1 text-[15px] font-semibold">{@preview.name}</span>
        <span
          :for={v <- @preview.variants}
          class="flex h-11 min-w-16 flex-none flex-col items-center justify-center rounded-md border-[1.5px] border-line bg-surface px-2 leading-tight"
        >
          <small :if={v.name != to_string(v.price)} class="text-[11px] text-muted">{v.name}</small>
          <b class="text-[17px]">{v.price}</b>
        </span>
      </div>
      <p class="text-[13px] leading-normal text-muted">
        มีหลายขนาดแต่ไม่มีตัวเลือก จะแสดงเป็นปุ่มราคาแบบนี้เอง แตะทีเดียวก็เพิ่ม
      </p>
    </div>
    """
  end

  defp preview(assigns) do
    ~H"""
    <div id="item-preview" class="flex flex-col gap-2.5">
      <span class="text-[14px] font-semibold">ตัวอย่าง (หน้ารับออเดอร์)</span>
      <div class="flex flex-col gap-3.5 rounded-xl border-[1.5px] border-line-soft bg-white p-4">
        <span class="text-[18px] font-bold">{@preview.name}</span>
        <.preview_group
          :if={length(@preview.variants) > 1}
          label="ขนาด"
          chips={
            for {v, i} <- Enum.with_index(@preview.variants) do
              {variant_chip(v, @preview.variants), i == 0}
            end
          }
        />
        <.preview_group
          :for={group <- @preview.groups}
          label={if(group.multi, do: "#{group.name} · เลือกได้หลายอย่าง", else: group.name)}
          chips={
            for {o, i} <- Enum.with_index(group.options) do
              {option_chip(o), group.required and not group.multi and i == 0}
            end
          }
        />
        <div class="flex items-baseline justify-between border-t border-dashed border-line pt-3">
          <span class="text-[15px] text-muted">ราคา</span>
          <span id="item-preview-price" class="text-[32px] leading-[1.1] font-bold">
            {@preview.price} <span class="text-[16px] font-semibold">บาท</span>
          </span>
        </div>
      </div>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :chips, :list, required: true

  defp preview_group(assigns) do
    ~H"""
    <div class="flex flex-col gap-1.5">
      <span class="text-[13px] text-muted">{@label}</span>
      <div class="flex flex-wrap gap-1.5">
        <span
          :for={{text, selected} <- @chips}
          class={[
            "rounded-full px-3 py-1.5 text-[14px]",
            if(selected, do: "bg-primary text-white", else: "border border-line")
          ]}
        >
          {text}
        </span>
      </div>
    </div>
    """
  end

  defp build_preview(assigns) do
    changeset = assigns.item_changeset
    item = Ecto.Changeset.apply_changes(changeset)

    variants =
      item.price_variants
      |> Enum.map(&%{name: blank_to(&1.name, "–"), price: &1.price || 0})

    groups = attached_groups(assigns)

    %{
      style: if(groups == [] and length(variants) > 1, do: :price_buttons, else: :full),
      name: blank_to(item.name, "ชื่อเมนู"),
      variants: variants,
      groups: groups,
      price: (List.first(variants) || %{price: 0}).price
    }
  end

  defp variant_chip(%{name: name, price: price}, [first | _]) do
    diff = price - first.price

    cond do
      diff > 0 -> "#{name} +#{diff}"
      diff < 0 -> "#{name} #{diff}"
      true -> name
    end
  end

  defp option_chip(option) do
    case Option.price_label(option) do
      nil -> option.name
      label -> "#{option.name} #{label}"
    end
  end

  # ---------------------------------------------------------------- helpers

  defp attached_groups(assigns) do
    Enum.map(assigns.attached_ids, &Map.fetch!(assigns.groups, &1))
  end

  defp option_labels(options) do
    Enum.map(options, fn option ->
      case Option.price_label(option) do
        nil -> option.name
        label -> "#{option.name} (#{label})"
      end
    end)
  end

  defp drinks?(form, categories) do
    id = to_string(form[:category_id].value)
    Enum.any?(categories, &(to_string(&1.id) == id and &1.name == @drinks))
  end

  defp multi?(form), do: checked?(form[:multi])

  defp checked?(%Phoenix.HTML.FormField{value: value}),
    do: Phoenix.HTML.Form.normalize_value("checkbox", value)

  defp back_query(form) do
    case form[:category_id].value do
      nil -> []
      "" -> []
      id -> [category: id]
    end
  end

  defp price_text_value(of) do
    case of[:price_text].value do
      nil -> Option.format_deltas(of[:price_deltas].value || [0])
      text -> text
    end
  end

  # A row the user just added (not saved, still empty) gets the focus.
  # (`phx-mounted` only runs when the row first appears, so later renders of
  # a still-empty row do not steal the focus.)
  defp new_blank_row?(f) do
    f.data.id == nil and f[:name].value in [nil, ""]
  end

  defp blank_to(nil, default), do: default
  defp blank_to("", default), do: default
  defp blank_to(value, _default), do: value

  defp errors(%Phoenix.HTML.FormField{errors: errors}) do
    Enum.map(errors, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
      end)
    end)
  end
end
