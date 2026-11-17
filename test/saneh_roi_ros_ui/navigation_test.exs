defmodule SanehRoiRosUI.NavigationTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosUI.Navigation

  describe "top_bar/1" do
    test "renders back link, title, subtitle and actions" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.top_bar id="top" title="โต๊ะ 1" subtitle="รอบที่ 2" back="/">
          <:actions><button id="move">ย้ายโต๊ะ</button></:actions>
        </UI.top_bar>
        """)

      assert attr(doc, "#top a[aria-label='ย้อนกลับ']", "href") == "/"
      assert text(doc, "#top b") == "โต๊ะ 1"
      assert text(doc, "#top small") == "รอบที่ 2"
      assert has?(doc, "#top #move")
    end

    test "has no back button without back" do
      doc = render(&Navigation.top_bar/1, id: "top", title: "รับออเดอร์", size: :lg)

      refute has?(doc, "a")
      assert "text-[22px]" in classes(doc, "#top b")
    end
  end

  describe "bottom_nav/1" do
    @items [
      %{key: :home, label: "หน้าแรก", icon: "hero-home", path: "/"},
      %{key: :orders, label: "ออเดอร์", icon: "hero-clipboard-document-list", path: "/orders"},
      %{key: :reports, label: "รายงาน", icon: "hero-chart-bar", path: "/reports", disabled: true}
    ]

    test "enabled items are links; current one is marked" do
      doc = render(&Navigation.bottom_nav/1, items: @items, current: :orders)

      assert attr(doc, "#bottom-nav-home", "href") == "/"
      assert attr(doc, "#bottom-nav-orders", "href") == "/orders"
      assert attr(doc, "#bottom-nav-orders", "aria-current") == "page"
      assert attr(doc, "#bottom-nav-home", "aria-current") == nil
      assert "text-primary" in classes(doc, "#bottom-nav-orders")
    end

    test "disabled items stay visible, grey, aria-disabled, and send on_disabled" do
      doc = render(&Navigation.bottom_nav/1, items: @items, on_disabled: "nav_disabled")

      assert attr(doc, "#bottom-nav-reports", "aria-disabled") == "true"
      assert attr(doc, "#bottom-nav-reports", "href") == nil
      assert attr(doc, "#bottom-nav-reports", "phx-click") == "nav_disabled"
      assert attr(doc, "#bottom-nav-reports", "phx-value-item") == "reports"
      assert "text-disabled" in classes(doc, "#bottom-nav-reports")
      assert text(doc, "#bottom-nav-reports") == "รายงาน"
      # no lock icon
      refute has?(doc, ".hero-lock-closed")
    end

    test "knows nothing about roles" do
      refute function_exported?(Navigation, :allowed?, 2)
      refute function_exported?(Navigation, :denied_message, 1)
    end
  end
end
