defmodule SanehRoiRosWeb.UIGalleryLiveTest do
  use SanehRoiRosWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  setup %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/dev/ui")
    %{view: view}
  end

  test "renders every component section", %{view: view} do
    for id <-
          ~w(spec-tabs spec-button spec-button-row spec-chip spec-quick-add spec-segment spec-stepper spec-tally spec-switch
             spec-list spec-section-label spec-list-row spec-card spec-tag spec-menu-tag spec-role-tag spec-option-group spec-tables spec-bottom-nav spec-main-nav spec-order-bar spec-toast spec-input spec-hint spec-login
             spec-top-bar spec-footer) do
      assert has_element?(view, "##{id}")
    end
  end

  test "app components and the UI kit are in separate groups, app first", %{view: view} do
    ids =
      view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#ui-gallery > [id]")
      |> LazyHTML.attribute("id")

    index = &Enum.find_index(ids, fn id -> id == &1 end)

    assert index.("group-web") < index.("spec-tabs")
    assert index.("spec-tabs") < index.("spec-quick-add")
    assert index.("spec-quick-add") < index.("group-ui")
    assert index.("spec-menu-tag") < index.("group-ui")
    assert index.("spec-role-tag") < index.("group-ui")
    assert index.("spec-main-nav") < index.("group-ui")
    assert index.("spec-order-bar") < index.("group-ui")
    assert index.("spec-login") < index.("group-ui")
    assert index.("spec-button-row") < index.("group-ui")
    assert index.("group-ui") < index.("spec-bottom-nav")
    assert index.("group-ui") < index.("spec-button")
    assert index.("group-ui") < index.("spec-top-bar")
  end

  test "option group rows show each selection label", %{view: view} do
    assert has_element?(view, "#group-noodle [data-kind=required]", "ต้องเลือก 1")
    assert has_element?(view, "#group-size [data-kind=single]", "เลือก 1")
    assert has_element?(view, "#group-no-add [data-kind=multi]", "เลือกได้หลายอย่าง")
  end

  test "category tabs select a category", %{view: view} do
    assert has_element?(view, "#tabs-0[aria-pressed=true]")

    view |> element("#tabs-4") |> render_click()

    assert has_element?(view, "#tabs-4[aria-pressed=true]")
    assert has_element?(view, "#tabs-0[aria-pressed=false]")
    assert has_element?(view, "#active-category", "เครื่องดื่ม")
  end

  test "single-choice chips behave like radios", %{view: view} do
    view |> element("#noodle-3") |> render_click()

    assert has_element?(view, "#noodle-3[aria-pressed=true]")
    assert has_element?(view, "#noodle-0[aria-pressed=false]")
  end

  test "multi-choice chips toggle", %{view: view} do
    view |> element("#no-add-1") |> render_click()
    view |> element("#no-add-2") |> render_click()
    assert has_element?(view, "#no-add-1[aria-pressed=true]")
    assert has_element?(view, "#no-add-2[aria-pressed=true]")

    view |> element("#no-add-1") |> render_click()
    assert has_element?(view, "#no-add-1[aria-pressed=false]")
  end

  test "segment switches value", %{view: view} do
    view |> element("#cone-โคน") |> render_click()
    assert has_element?(view, "#cone-โคน[aria-pressed=true]")
    assert has_element?(view, "#cone-ถ้วย[aria-pressed=false]")
  end

  test "stepper counts up from zero and back down to zero", %{view: view} do
    assert has_element?(view, "#step-bottle-minus[aria-disabled=true]")

    view |> element("#step-bottle-plus") |> render_click()
    assert has_element?(view, "#step-bottle-value", "1")
    assert has_element?(view, "#step-bottle[data-active]")

    view |> element("#step-bottle-minus") |> render_click()
    assert has_element?(view, "#step-bottle-value", "0")
    refute has_element?(view, "#step-bottle[data-active]")
    assert has_element?(view, "#step-bottle-minus[aria-disabled=true]")
  end

  test "stepper with min=1 stops at 1", %{view: view} do
    assert has_element?(view, "#step-bowls[data-active]")
    assert has_element?(view, "#step-bowls-minus[aria-disabled=true]")

    view |> element("#step-bowls-plus") |> render_click()
    assert has_element?(view, "#step-bowls-value", "2")
    assert has_element?(view, "#step-bowls-minus[aria-disabled=false]")

    view |> element("#step-bowls-minus") |> render_click()
    assert has_element?(view, "#step-bowls-value", "1")
    assert has_element?(view, "#step-bowls-minus[aria-disabled=true]")
  end

  test "stepper at max cannot go higher but can go down", %{view: view} do
    assert has_element?(view, "#step-eggs-plus[aria-disabled=true]")

    view |> element("#step-eggs-minus") |> render_click()
    assert has_element?(view, "#step-eggs-value", "2")
    assert has_element?(view, "#step-eggs-plus[aria-disabled=false]")
  end

  test "tally button label example shows real quotes, not &quot;", %{view: view} do
    html = view |> element("#variant-tally-label code") |> render()
    text = html |> LazyHTML.from_fragment() |> LazyHTML.text()

    assert text == ~s(label="ขวด")
  end

  test "plain price button keeps counting and shows no toast", %{view: view} do
    view |> element("#tally-count") |> render_click()
    view |> element("#tally-count") |> render_click()

    assert has_element?(view, "#tally-count-count", "4")
    refute has_element?(view, "#toast")
  end

  test "price button adds one, shows a badge and an undo toast", %{view: view} do
    refute has_element?(view, "#soda-coke-cup-count")
    assert has_element?(view, "#order-bar-count", "2")

    view |> element("#soda-coke-cup") |> render_click()

    assert has_element?(view, "#soda-coke-cup-count", "1")
    assert has_element?(view, "#order-bar-count", "3")
    assert has_element?(view, "#order-bar-total", "57 บาท")
    assert has_element?(view, "#toast", "เพิ่ม โค้ก แก้วใหญ่ แล้ว (รวม 1)")

    view |> element("#toast-action") |> render_click()

    refute has_element?(view, "#toast")
    refute has_element?(view, "#soda-coke-cup-count")
    assert has_element?(view, "#order-bar-count", "2")
  end

  test "the toast clears itself only for its own key", %{view: view} do
    view |> element("#soda-sprite-can") |> render_click()
    assert has_element?(view, "#toast")

    render_hook(view, "toast_dismiss", %{"key" => "stale"})
    assert has_element?(view, "#toast")

    key = view |> element("#toast") |> render() |> LazyHTML.from_fragment()
    [key] = key |> LazyHTML.query("#toast") |> LazyHTML.attribute("data-key")

    render_hook(view, "toast_dismiss", %{"key" => key})
    refute has_element?(view, "#toast")
  end

  test "switches toggle aria-checked", %{view: view} do
    assert has_element?(view, "#switch-bag[aria-checked=false]")
    view |> element("#switch-bag") |> render_click()
    assert has_element?(view, "#switch-bag[aria-checked=true]")
  end

  test "sold-out row reopens with its switch", %{view: view} do
    assert has_element?(view, "#row-soldout[data-soldout]")
    view |> element("#switch-soldout") |> render_click()
    refute has_element?(view, "#row-soldout[data-soldout]")
  end

  test "denied bottom-nav items show a no-permission toast", %{view: view} do
    assert has_element?(view, "#nav-sales[aria-disabled=true]")

    view |> element("#nav-sales") |> render_click()
    assert has_element?(view, "#toast", "ยอดขาย เปิดได้เฉพาะเจ้าของร้าน")
    refute has_element?(view, "#toast-action")

    view |> element("#nav-role-owner") |> render_click()
    refute has_element?(view, "#nav [aria-disabled]")
    assert has_element?(view, "#nav-sales[href='/sales']")
  end

  test "keypad fills the PIN dots up to four digits", %{view: view} do
    for d <- ~w(1 2 3 4 5) do
      view |> element("#keypad-#{d}") |> render_click()
    end

    assert has_element?(view, "#pin[aria-label='ใส่รหัสแล้ว 4 จาก 4 หลัก']")

    view |> element("#keypad-backspace") |> render_click()
    assert has_element?(view, "#pin[aria-label='ใส่รหัสแล้ว 3 จาก 4 หลัก']")

    view |> element("#staff-2") |> render_click()
    assert has_element?(view, "#staff-2[aria-pressed=true]")
    assert has_element?(view, "#pin[aria-label='ใส่รหัสแล้ว 0 จาก 4 หลัก']")

    view |> element("#keypad-extra") |> render_click()
    assert has_element?(view, "#pin[aria-label='ใส่รหัสแล้ว 4 จาก 4 หลัก']")
  end

  test "input shows a validation error", %{view: view} do
    view |> form("#takeaway-form", takeaway: %{customer: ""}) |> render_change()
    assert has_element?(view, "#takeaway_customer[aria-invalid=true]")
  end
end
