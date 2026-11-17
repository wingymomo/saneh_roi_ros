defmodule SanehRoiRosUI.ButtonsTest do
  use SanehRoiRosUI.ComponentCase, async: true

  describe "button/1" do
    test "renders a type=button with the variant styling" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.button id="b" variant={:primary} phx-click="send">ส่งครัว + คิดเงิน · 220</UI.button>
        """)

      assert attr(doc, "button#b", "type") == "button"
      assert attr(doc, "button#b", "phx-click") == "send"
      assert text(doc, "#b") == "ส่งครัว + คิดเงิน · 220"
      assert "bg-primary" in classes(doc, "#b")
      assert "h-14" in classes(doc, "#b")
    end

    test "each variant gets its own colours" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.button id="s" variant={:secondary}>a</UI.button>
        <UI.button id="d" variant={:dashed}>b</UI.button>
        <UI.button id="x" variant={:danger}>c</UI.button>
        """)

      assert "bg-surface" in classes(doc, "#s")
      assert "border-dashed" in classes(doc, "#d")
      assert "text-danger" in classes(doc, "#x")
    end

    test "defaults to secondary, supports sm size and block" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.button id="b" size={:sm} block>ย้ายโต๊ะ</UI.button>
        """)

      assert "border-line" in classes(doc, "#b")
      assert "h-10" in classes(doc, "#b")
      assert "w-full" in classes(doc, "#b")
    end

    test "lg size is 56px for every variant" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.button id="s" size={:lg}>a</UI.button>
        <UI.button id="p" size={:lg} variant={:primary}>b</UI.button>
        """)

      assert "h-14" in classes(doc, "#s")
      assert "h-14" in classes(doc, "#p")
    end

    test "renders a link when given navigate" do
      assigns = %{}
      doc = parse(~H|<UI.button id="b" navigate="/tables">โต๊ะ</UI.button>|)

      assert has?(doc, "a#b[href='/tables'][data-phx-link='redirect']")
      refute has?(doc, "button")
    end

    test "forwards disabled and type" do
      assigns = %{}
      doc = parse(~H|<UI.button id="b" type="submit" disabled>บันทึก</UI.button>|)

      assert has?(doc, "button#b[type='submit'][disabled]")
    end
  end

  test "a disabled button with navigate stays a disabled button, not a live link" do
    assigns = %{}
    doc = parse(~H|<UI.button id="b" navigate="/pay" disabled>คิดเงิน</UI.button>|)

    assert has?(doc, "button#b[disabled]")
    refute has?(doc, "a")
    assert attr(doc, "#b", "href") == nil
    assert attr(doc, "#b", "data-phx-link") == nil
  end
end
