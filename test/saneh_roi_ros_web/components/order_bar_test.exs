defmodule SanehRoiRosWeb.OrderBarTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosWeb.OrderBar

  describe "order_bar/1" do
    test "shows count, caption, total in baht and a CTA button" do
      doc = render(&OrderBar.order_bar/1, count: 3, total: 170, "phx-click": "summary")

      assert text(doc, "#order-bar-count") == "3"
      assert text(doc, "#order-bar-total") == "170 บาท"
      assert text(doc, "#order-bar") =~ "ยังไม่ส่งครัว"
      assert attr(doc, "button#order-bar-cta", "phx-click") == "summary"
      assert text(doc, "#order-bar-cta") == "สรุปออเดอร์ →"
      assert "fixed" in classes(doc, "#order-bar")
    end

    test "CTA becomes a link with navigate; position can be absolute" do
      doc =
        render(&OrderBar.order_bar/1, count: 1, total: 60, navigate: "/sum", position: :absolute)

      assert attr(doc, "a#order-bar-cta", "href") == "/sum"
      assert "absolute" in classes(doc, "#order-bar")
    end
  end

  test "a disabled CTA with navigate is a disabled button" do
    doc = render(&OrderBar.order_bar/1, count: 0, total: 0, navigate: "/sum", disabled: true)

    assert has?(doc, "button#order-bar-cta[disabled]")
    refute has?(doc, "a#order-bar-cta")
  end
end
