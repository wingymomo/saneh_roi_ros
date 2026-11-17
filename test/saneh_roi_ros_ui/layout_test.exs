defmodule SanehRoiRosUI.LayoutTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosUI.Layout

  describe "screen/1" do
    test "renders top, body and bottom slots; body reserves room for the order bar" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.screen id="scr">
          <:top>
            <header id="t">top</header>
          </:top>
          <p id="body">body</p>
          <:bottom>
            <footer id="f">bottom</footer>
          </:bottom>
        </UI.screen>
        """)

      assert has?(doc, "#scr > #t")
      assert has?(doc, "#scr > #f")
      assert "pb-[110px]" in classes(doc, "#scr > div")
      assert has?(doc, "#scr > div > #body")
    end
  end

  describe "card/1" do
    test "variants" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.card id="a">a</UI.card>
        <UI.card id="b" variant={:elevated}>b</UI.card>
        <UI.card id="c" variant={:highlighted}>c</UI.card>
        """)

      assert attr(doc, "#a", "data-variant") == "base"
      assert "bg-surface" in classes(doc, "#a")
      assert "bg-white" in classes(doc, "#b")
      assert "border-2" in classes(doc, "#c")
      assert "border-primary" in classes(doc, "#c")
    end
  end

  describe "list_row/1" do
    test "with phx-click renders a button with a chevron" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.list>
          <UI.list_row
            id="r"
            title="รายชื่อพนักงาน"
            subtitle="ใช้งาน 4 คน"
            phx-click="go"
          >
            <:icon><i id="ic" /></:icon>
          </UI.list_row>
        </UI.list>
        """)

      assert attr(doc, "button#r", "phx-click") == "go"
      assert text(doc, "#r b") == "รายชื่อพนักงาน"
      assert text(doc, "#r small") == "ใช้งาน 4 คน"
      assert has?(doc, "#r #ic")
      assert has?(doc, "#r .hero-chevron-right")
    end

    test "with navigate renders a link" do
      doc = render(&Layout.list_row/1, id: "r", title: "ตั้งค่า", navigate: "/settings")
      assert attr(doc, "a#r", "href") == "/settings"
    end

    test "with a trailing control renders a div (never a button inside a button)" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.list_row id="r" title="เย็นตาโฟต้มยำ" soldout phx-click="ignored">
          <:badge>
            <UI.tag variant={:accent}>หมดวันนี้</UI.tag>
          </:badge>
          <:trailing><UI.switch id="sw" checked={false} /></:trailing>
        </UI.list_row>
        """)

      assert has?(doc, "div#r")
      refute has?(doc, "button#r")
      refute has?(doc, "button button")
      assert has?(doc, "div#r button#sw")
      assert attr(doc, "#r", "data-soldout") == ""
      assert "bg-soldout" in classes(doc, "#r")
      assert text(doc, "#r b") =~ "หมดวันนี้"
      refute has?(doc, "#r .hero-chevron-right")
    end
  end

  test "section_label, hint and note_tag" do
    assigns = %{}

    doc =
      parse(~H"""
      <UI.section_label>จัดการพนักงาน</UI.section_label>
      <UI.hint id="h">ถามลูกค้าให้ครบก่อน</UI.hint>
      <UI.note_tag id="n">หมายเหตุ: แยกน้ำ</UI.note_tag>
      """)

    assert text(doc, "span.text-muted") == "จัดการพนักงาน"
    assert "bg-sand" in classes(doc, "#h")
    assert "text-brown" in classes(doc, "#n")
  end

  describe "footer_bar/1" do
    test "with and without total" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.footer_bar id="f1" total={1250}><button>เสร็จ</button></UI.footer_bar>
        <UI.footer_bar id="f2"><button>ส่ง</button></UI.footer_bar>
        """)

      assert text(doc, "#f1 [data-role=total]") == "1,250 บาท"
      assert "sticky" in classes(doc, "#f1")
      refute has?(doc, "#f2 [data-role=total]")
    end
  end

  describe "toast/1" do
    test "is wired to the Toast hook with key, duration and dismiss event" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.toast
          id="t"
          key="k1"
          duration={2000}
          action="ยกเลิก"
          on_action="undo"
          on_dismiss="clear"
        >
          เพิ่ม ชาไทย แก้ว แล้ว (รวม 2)
        </UI.toast>
        """)

      assert attr(doc, "#t", "phx-hook") =~ "Toast"
      assert attr(doc, "#t", "role") == "status"
      assert attr(doc, "#t", "data-key") == "k1"
      assert attr(doc, "#t", "data-duration") == "2000"
      assert attr(doc, "#t", "data-on-dismiss") == "clear"
      assert text(doc, "#t span") == "เพิ่ม ชาไทย แก้ว แล้ว (รวม 2)"
      assert attr(doc, "#t-action", "phx-click") == "undo"
      assert text(doc, "#t-action") == "ยกเลิก"
    end

    test "has no action button without action" do
      assigns = %{}
      doc = parse(~H|<UI.toast id="t">ยอดขาย เปิดได้เฉพาะเจ้าของร้าน</UI.toast>|)

      refute has?(doc, "#t-action")
      assert attr(doc, "#t", "data-duration") == "4000"
    end
  end

  test "a disabled list_row with navigate is not a link" do
    doc =
      render(&Layout.list_row/1, id: "r", title: "ตั้งค่า", navigate: "/settings", disabled: true)

    refute has?(doc, "a")
    assert attr(doc, "#r", "href") == nil
  end
end
