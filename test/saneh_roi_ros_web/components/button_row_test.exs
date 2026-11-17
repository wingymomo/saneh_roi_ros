defmodule SanehRoiRosWeb.ButtonRowTest do
  use SanehRoiRosUI.ComponentCase, async: true

  import SanehRoiRosWeb.ButtonRow

  describe "button_row/1" do
    test "renders secondary (flex-1) and primary (flex-2) with their attributes" do
      assigns = %{}

      doc =
        parse(~H"""
        <.button_row id="row">
          <:secondary id="cancel" phx-click="cancel">ยกเลิก</:secondary>
          <:primary id="save" type="submit">บันทึก · เพิ่ม ฝน</:primary>
        </.button_row>
        """)

      assert attr(doc, "#cancel", "phx-click") == "cancel"
      assert "flex-1" in classes(doc, "#cancel")
      assert attr(doc, "#save", "type") == "submit"
      assert "flex-[2]" in classes(doc, "#save")
      # same height for both, even though secondary is 52px on its own
      assert "h-14" in classes(doc, "#cancel")
      assert "h-14" in classes(doc, "#save")
      refute "h-[52px]" in classes(doc, "#cancel")
      assert "bg-primary" in classes(doc, "#save")
    end

    test "slots with navigate / patch / href render working links" do
      assigns = %{}

      doc =
        parse(~H"""
        <.button_row id="row">
          <:secondary id="back" navigate="/tables">กลับ</:secondary>
          <:primary id="pay" patch="/tables/1/pay">คิดเงิน · 220</:primary>
        </.button_row>
        """)

      assert attr(doc, "a#back", "href") == "/tables"
      assert attr(doc, "a#back", "data-phx-link") == "redirect"
      assert attr(doc, "a#pay", "href") == "/tables/1/pay"
      assert attr(doc, "a#pay", "data-phx-link") == "patch"
      refute has?(doc, "button")
      # same look as the button versions
      assert "flex-1" in classes(doc, "#back")
      assert "flex-[2]" in classes(doc, "#pay")
      assert "h-14" in classes(doc, "#back")
      assert "bg-primary" in classes(doc, "#pay")

      href =
        parse(
          ~H|<.button_row><:secondary id="h" href="/x">x</:secondary><:primary>y</:primary></.button_row>|
        )

      assert attr(href, "a#h", "href") == "/x"
    end
  end
end
