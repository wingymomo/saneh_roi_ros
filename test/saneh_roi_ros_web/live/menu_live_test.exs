defmodule SanehRoiRosWeb.MenuLiveTest do
  use SanehRoiRosWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import SanehRoiRos.MenuFixtures

  alias SanehRoiRos.Menu

  # The fixed categories come from a migration.
  setup do
    categories = Map.new(Menu.list_categories(), &{&1.name, &1})
    %{noodles: categories["ก๋วยเตี๋ยว"], drinks: categories["เครื่องดื่ม"]}
  end

  describe "access" do
    test "staff cannot open menu management", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"staff_role" => "staff"})

      assert {:error, {:redirect, %{to: "/", flash: %{"error" => msg}}}} = live(conn, ~p"/menu")
      assert msg =~ "ผู้จัดการ"
    end

    test "managers can", %{conn: conn} do
      conn = Plug.Test.init_test_session(conn, %{"staff_role" => "manager"})
      assert {:ok, _view, _html} = live(conn, ~p"/menu")
    end
  end

  describe "index" do
    test "lists the first category and switches tabs", %{conn: conn} = ctx do
      item = item_fixture(category_id: ctx.noodles.id, name: "น้ำตก")
      drink = item_fixture(category_id: ctx.drinks.id, name: "ชาไทย")

      {:ok, view, _html} = live(conn, ~p"/menu")
      assert has_element?(view, "#items-#{item.id}")
      refute has_element?(view, "#items-#{drink.id}")

      view |> element("#menu-tabs button", "เครื่องดื่ม") |> render_click()
      assert_patch(view, ~p"/menu?#{[category: ctx.drinks.id]}")
      assert has_element?(view, "#items-#{drink.id}")
      refute has_element?(view, "#items-#{item.id}")
    end

    test "searches every category by name or short name", %{conn: conn} = ctx do
      item = item_fixture(category_id: ctx.noodles.id, name: "น้ำตก", short_names: "เรือ")
      drink = item_fixture(category_id: ctx.drinks.id, name: "ชาไทย")

      {:ok, view, _html} = live(conn, ~p"/menu")

      view |> form("#menu-search", search: %{q: "ชา"}) |> render_change()
      assert has_element?(view, "#items-#{drink.id}")
      refute has_element?(view, "#items-#{item.id}")

      view |> form("#menu-search", search: %{q: "เรือ"}) |> render_change()
      assert has_element?(view, "#items-#{item.id}")

      view |> form("#menu-search", search: %{q: "ไม่มีแน่นอน"}) |> render_change()
      assert has_element?(view, "#menu-items-empty")
    end

    test "switch marks an item sold out today, with undo", %{conn: conn} = ctx do
      item = item_fixture(category_id: ctx.noodles.id)
      {:ok, view, _html} = live(conn, ~p"/menu")

      view |> element("#items-#{item.id}-switch") |> render_click()
      assert has_element?(view, "#items-#{item.id}[data-sold-out]")
      assert has_element?(view, "#items-#{item.id}-switch[aria-checked=false]")
      assert has_element?(view, "#menu-status", "หมดวันนี้ 1")
      assert Menu.sold_out?(Menu.get_item!(item.id), Menu.today())

      view |> element("#toast-action") |> render_click()
      assert has_element?(view, "#items-#{item.id}-switch[aria-checked=true]")
      refute Menu.sold_out?(Menu.get_item!(item.id), Menu.today())
    end
  end

  describe "form" do
    test "creates an item with sizes", %{conn: conn} = ctx do
      {:ok, view, _html} = live(conn, ~p"/menu/new?#{[category: ctx.noodles.id]}")

      # "+ เพิ่มขนาด" sends the form's change event with a "new" sort entry.
      view |> form("#item-form") |> render_change(%{"item" => %{"variants_sort" => ["0", "new"]}})
      assert has_element?(view, "#variant-row-1")
      assert has_element?(view, "#add-variant[name='item[variants_sort][]'][value=new]")

      view
      |> form("#item-form",
        item: %{
          name: "น้ำใส",
          price_variants: %{
            "0" => %{name: "ธรรมดา", price: "50"},
            "1" => %{name: "พิเศษ", price: "60"}
          }
        }
      )
      |> render_submit()

      flash = assert_redirect(view, ~p"/menu?#{[category: ctx.noodles.id]}")
      assert flash["info"] == "บันทึก น้ำใส แล้ว"

      assert [%{name: "น้ำใส", price_variants: [%{price: 50}, %{price: 60}]}] =
               Menu.list_items(ctx.noodles.id)
    end

    test "shows errors and keeps the page", %{conn: conn} = ctx do
      {:ok, view, _html} = live(conn, ~p"/menu/new?#{[category: ctx.noodles.id]}")

      html =
        view
        |> form("#item-form", item: %{name: "", price_variants: %{"0" => %{name: "", price: ""}}})
        |> render_submit()

      assert html =~ "ต้องกรอกชื่อเมนู"
      assert Menu.list_items(ctx.noodles.id) == []
    end

    test "drink group only shows for เครื่องดื่ม", %{conn: conn} = ctx do
      {:ok, view, _html} = live(conn, ~p"/menu/new?#{[category: ctx.noodles.id]}")
      refute has_element?(view, "#item-drink-group")

      view |> form("#item-form", item: %{category_id: ctx.drinks.id}) |> render_change()
      assert has_element?(view, "#item-drink-group")
    end

    test "multi-price item without options previews as price buttons", %{conn: conn} = ctx do
      {:ok, view, _html} = live(conn, ~p"/menu/new?#{[category: ctx.noodles.id]}")

      view |> form("#item-form") |> render_change(%{"item" => %{"variants_sort" => ["0", "new"]}})

      view
      |> form("#item-form",
        item: %{
          name: "ลูกชิ้นลวก",
          price_variants: %{"0" => %{name: "30", price: "30"}, "1" => %{name: "40", price: "40"}}
        }
      )
      |> render_change()

      assert has_element?(view, "#item-preview", "แตะทีเดียวก็เพิ่ม")
    end

    test "creates a new option group, attaches it and keeps unsaved input",
         %{conn: conn} = ctx do
      {:ok, view, _html} = live(conn, ~p"/menu/new?#{[category: ctx.noodles.id]}")

      view |> form("#item-form", item: %{name: "แห้ง"}) |> render_change()

      view |> element("#add-group") |> render_click()
      assert_patch(view, ~p"/menu/new?group=pick")

      view |> element("#new-group") |> render_click()
      assert_patch(view, ~p"/menu/new?group=new")

      view
      |> form("#group-form")
      |> render_change(%{"group" => %{"options_sort" => ["0", "new"]}})

      assert has_element?(view, "#option-row-1")

      view
      |> form("#group-form",
        group: %{
          name: "เนื้อสัตว์",
          multi: "false",
          required: "true",
          options: %{
            "0" => %{name: "หมูตุ๋น", price_text: ""},
            "1" => %{name: "ทะเล", price_text: "40 / 70"}
          }
        }
      )
      |> render_submit()

      assert_patch(view, ~p"/menu/new")
      assert has_element?(view, "#item-form input[name='item[name]'][value='แห้ง']")
      [group] = Menu.list_option_groups()
      assert has_element?(view, "#item-group-#{group.id}", "ทะเล (+40 / +70)")

      view
      |> form("#item-form", item: %{price_variants: %{"0" => %{price: "50"}}})
      |> render_submit()

      [item] = Menu.list_items(ctx.noodles.id)
      assert item.name == "แห้ง"
      assert [%{option_group_id: id}] = item.item_option_groups
      assert id == group.id
    end

    test "attaches an existing group and detaches it again", %{conn: conn} = ctx do
      group = option_group_fixture(%{"name" => "เส้น"})
      item = item_fixture(category_id: ctx.noodles.id)

      {:ok, view, _html} = live(conn, ~p"/menu/#{item.id}/edit")
      view |> element("#add-group") |> render_click()
      view |> element("#pick-group-#{group.id}") |> render_click()
      assert_patch(view, ~p"/menu/#{item.id}/edit")
      assert has_element?(view, "#item-group-#{group.id}")

      view |> element("#item-group-#{group.id}") |> render_click()
      assert has_element?(view, "#detach-group")
      view |> element("#detach-group") |> render_click()
      refute has_element?(view, "#item-group-#{group.id}")

      view |> form("#item-form") |> render_submit()
      assert Menu.get_item!(item.id).item_option_groups == []
    end

    test "editing a shared group warns about the other items", %{conn: conn} = ctx do
      group = option_group_fixture(%{"name" => "เส้น"})
      item = item_fixture(category_id: ctx.noodles.id, option_group_ids: [group.id])
      item_fixture(category_id: ctx.noodles.id, option_group_ids: [group.id])

      {:ok, view, _html} = live(conn, ~p"/menu/#{item.id}/edit?group=#{group.id}")
      assert has_element?(view, "#group-shared-hint", "2 เมนู")
    end
  end
end
