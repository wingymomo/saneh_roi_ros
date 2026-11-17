defmodule SanehRoiRosWeb.Features.UIComponentsTest do
  @moduledoc """
  Browser tests for the SanehRoiRosUI components that ship JavaScript
  (category tabs and toast), plus a check that the design tokens reach the
  rendered page.
  """
  use SanehRoiRosWeb.FeatureCase, async: false

  @gallery "/dev/ui"

  defp open_gallery(session, query \\ "") do
    session
    |> resize_window(390, 844)
    |> visit(@gallery <> query)
    |> assert_has(css("#ui-gallery"))
    # the LiveView socket is connected once phx-connected is set on the root
    |> assert_has(css(".phx-connected"))
  end

  defp compact?(session),
    do: eval_js(session, ~s|return document.getElementById("tabs").hasAttribute("data-compact")|)

  defp scroll_to(session, y) do
    eval_js(session, "window.scrollTo(0, arguments[0]); return window.scrollY", [y])
    session
  end

  feature "brand tokens are applied (not overridden by daisyUI)", %{session: session} do
    session = open_gallery(session)

    assert computed_style(session, "#btn-primary", "background-color") == "rgb(5, 76, 76)"
    assert computed_style(session, "#btn-secondary", "background-color") == "rgb(255, 250, 240)"
    assert computed_style(session, "#btn-primary", "font-family") =~ "IBM Plex Sans Thai"
  end

  describe "selection controls" do
    # LiveViewTest's render_click only reads phx-value-* attributes; the
    # browser also sends the button's own .value, so these need a real browser.
    feature "chips select (radio) and toggle (multi)", %{session: session} do
      session = open_gallery(session)

      session |> click_centered("#noodle-3")
      assert_has(session, css("#noodle-3[aria-pressed='true']"))
      assert_has(session, css("#noodle-0[aria-pressed='false']"))

      session |> click_centered("#no-add-1")
      assert_has(session, css("#no-add-1[aria-pressed='true']"))
      session |> click_centered("#no-add-1")
      assert_has(session, css("#no-add-1[aria-pressed='false']"))
    end

    feature "segment switches value", %{session: session} do
      session = open_gallery(session)

      session |> click_centered("#cone-โคน")
      assert_has(session, css("#cone-โคน[aria-pressed='true']"))

      session |> click_centered("#nav-role-owner")
      assert_has(session, css("#nav-role-owner[aria-pressed='true']"))
      assert_has(session, css("#nav-sales[href='/sales']"))
    end
  end

  describe "category tabs" do
    feature "expanded at the top, compact and sticky after scrolling down", %{session: session} do
      session = open_gallery(session)

      refute compact?(session)
      assert computed_style(session, "#tabs", "flex-wrap") == "wrap"

      scroll_to(session, 600)

      eventually(fn -> compact?(session) end)
      assert computed_style(session, "#tabs", "flex-wrap") == "nowrap"
      assert computed_style(session, "#tabs", "position") == "sticky"
      # no fade on the left/right edges
      assert computed_style(session, "#tabs", "mask-image") == "none"

      # stuck to the top of the viewport
      top =
        eval_js(session, ~s|return document.getElementById("tabs").getBoundingClientRect().top|)

      assert_in_delta top, 0, 1

      scroll_to(session, 0)
      eventually(fn -> not compact?(session) end)
      assert computed_style(session, "#tabs", "flex-wrap") == "wrap"
    end

    feature "stays compact across LiveView patches and keeps the active tab in view",
            %{session: session} do
      session = open_gallery(session) |> scroll_to(600)
      eventually(fn -> compact?(session) end)

      session |> click(css("#tabs-6"))

      assert_has(session, css("#tabs-6[aria-pressed='true']"))
      assert_has(session, css("#active-category", text: "ขนมถุง"))
      assert compact?(session), "compact mode was lost after the server patch"

      eventually(fn ->
        eval_js(session, """
        const nav = document.getElementById("tabs").getBoundingClientRect();
        const tab = document.getElementById("tabs-6").getBoundingClientRect();
        return tab.left >= nav.left - 1 && tab.right <= nav.right + 1;
        """)
      end)
    end
  end

  describe "toast" do
    feature "appears on tap, then dismisses itself and clears the server state",
            %{session: session} do
      session = open_gallery(session, "?toast_ms=1500")

      session |> click_centered("#soda-sprite-cup")

      assert_has(session, css("#toast", text: "เพิ่ม สไปรท์ แก้วใหญ่ แล้ว (รวม 1)"))
      assert_has(session, css("#soda-sprite-cup-count", text: "1"))

      # after the timeout the hook hides it and pushes clear_toast → removed
      assert_has(session, css("#toast", count: 0))
      assert_has(session, css("#soda-sprite-cup-count", text: "1"))
    end

    feature "a new message restarts the timer", %{session: session} do
      session = open_gallery(session, "?toast_ms=1500")

      session |> click_centered("#soda-coke-can")
      assert_has(session, css("#toast", text: "รวม 3"))

      Process.sleep(900)
      session |> click_centered("#soda-coke-can")
      assert_has(session, css("#toast", text: "รวม 4"))

      # 900ms after the second tap the first timer would have fired already
      Process.sleep(900)
      assert_has(session, css("#toast", text: "รวม 4"))

      assert_has(session, css("#toast", count: 0))
    end

    feature "the undo action reverts the add", %{session: session} do
      session = open_gallery(session, "?toast_ms=0")

      session |> click_centered("#soda-coke-glass_bottle")
      assert_has(session, css("#soda-coke-glass_bottle-count", text: "1"))

      session |> click_centered("#toast-action")

      assert_has(session, css("#toast", count: 0))
      assert_has(session, css("#soda-coke-glass_bottle-count", count: 0))
    end

    feature "denied bottom-nav item shows the no-permission toast", %{session: session} do
      session = open_gallery(session, "?toast_ms=0")

      session |> click_centered("#nav-settings")

      assert_has(session, css("#toast", text: "ตั้งค่า เปิดได้เฉพาะเจ้าของร้าน"))
      refute_has(session, css("#toast-action"))
    end
  end
end
