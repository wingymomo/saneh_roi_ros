defmodule SanehRoiRosUI.ControlsTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosUI.Controls

  describe "chip/1" do
    test "selected chip is pressed and filled" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.chips id="chips">
          <UI.chip id="on" selected phx-click="pick" phx-value-name="เส้นเล็ก">
            เส้นเล็ก
          </UI.chip>
          <UI.chip id="off">เส้นใหญ่</UI.chip>
        </UI.chips>
        """)

      assert "flex-wrap" in classes(doc, "#chips")
      assert attr(doc, "#on", "aria-pressed") == "true"
      assert "bg-primary" in classes(doc, "#on")
      assert attr(doc, "#on", "phx-value-name") == "เส้นเล็ก"
      assert attr(doc, "#off", "aria-pressed") == "false"
      assert "bg-surface" in classes(doc, "#off")
    end
  end

  describe "segment/1" do
    test "marks the current value and sends on_select with the value" do
      doc =
        render(&Controls.segment/1,
          id: "cone",
          options: ["ถ้วย", "โคน"],
          value: "โคน",
          on_select: "set"
        )

      assert attr(doc, "#cone-ถ้วย", "aria-pressed") == "false"
      assert attr(doc, "#cone-โคน", "aria-pressed") == "true"
      assert attr(doc, "#cone-โคน", "phx-click") == "set"
      assert attr(doc, "#cone-โคน", "value") == "โคน"
    end

    test "accepts {value, label} tuples and atom values" do
      doc =
        render(&Controls.segment/1,
          id: "role",
          options: [{"staff", "พนักงาน"}, {"manager", "ผู้จัดการ"}],
          value: :manager
        )

      assert text(doc, "#role-staff") == "พนักงาน"
      assert attr(doc, "#role-manager", "aria-pressed") == "true"
    end
  end

  describe "stepper/1" do
    test "at zero: inactive look, minus is aria-disabled and sends nothing" do
      doc = render(&Controls.stepper/1, id: "s", value: 0, on_change: "step")

      assert attr(doc, "#s", "data-active") == nil
      assert "border-line" in classes(doc, "#s")
      assert attr(doc, "#s-minus", "aria-disabled") == "true"
      assert attr(doc, "#s-minus", "phx-click") == nil
      assert attr(doc, "#s-plus", "phx-click") == "step"
      assert attr(doc, "#s-plus", "phx-value-delta") == "1"
      assert "text-disabled" in classes(doc, "#s-value")
      assert text(doc, "#s-value") == "0"
    end

    test "above zero: active look and both buttons send deltas with params" do
      doc =
        render(&Controls.stepper/1,
          id: "s",
          value: 2,
          on_change: "step",
          params: %{key: "thai-tea", bowl: 1}
        )

      assert attr(doc, "#s", "data-active") == ""
      assert "border-primary" in classes(doc, "#s")
      assert attr(doc, "#s-minus", "aria-disabled") == "false"
      assert attr(doc, "#s-minus", "phx-click") == "step"
      assert attr(doc, "#s-minus", "phx-value-delta") == "-1"
      assert attr(doc, "#s-minus", "phx-value-key") == "thai-tea"
      assert attr(doc, "#s-plus", "phx-value-bowl") == "1"
      assert "bg-primary" in classes(doc, "#s-plus")
      assert "font-bold" in classes(doc, "#s-value")
    end

    test "min above zero: active look, but minus disabled at min" do
      doc = render(&Controls.stepper/1, id: "s", value: 1, min: 1, on_change: "step")

      assert attr(doc, "#s", "data-active") == ""
      assert attr(doc, "#s-minus", "aria-disabled") == "true"
      assert attr(doc, "#s-minus", "phx-click") == nil
    end

    test "respects max" do
      doc = render(&Controls.stepper/1, id: "s", value: 3, max: 3, on_change: "step")

      assert attr(doc, "#s-plus", "aria-disabled") == "true"
      assert attr(doc, "#s-plus", "phx-click") == nil
    end

    test "sm size is compact" do
      doc = render(&Controls.stepper/1, id: "s", value: 1, size: :sm)

      assert "h-9" in classes(doc, "#s")
      assert "w-9" in classes(doc, "#s-minus")
    end
  end

  describe "tally_button/1" do
    test "without a count: no badge, not ordered" do
      doc = render(&Controls.tally_button/1, id: "p", price: 15)

      assert text(doc, "#p") == "15"
      refute has?(doc, "#p-count")
      assert attr(doc, "#p", "data-ordered") == nil
    end

    test "with a count: ordered look and a badge" do
      doc = render(&Controls.tally_button/1, id: "p", price: 16, count: 2, label: "กระป๋อง")

      assert attr(doc, "#p", "data-ordered") == ""
      assert "border-primary" in classes(doc, "#p")
      assert text(doc, "#p-count") == "2"
      assert text(doc, "#p") =~ "กระป๋อง"
    end

    test "cell_empty is a dash, not a button" do
      doc = render(&Controls.cell_empty/1, %{})

      assert text(doc, "span") == "–"
      refute has?(doc, "button")
    end
  end

  describe "price_row/1 and col_head/1" do
    test "renders the name and cells" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.price_row id="r" name="ชาไทย">
          <UI.col_head label="ขวด" price={20} />
        </UI.price_row>
        """)

      assert text(doc, "#r") =~ "ชาไทย"
      assert text(doc, "#r small") == "20"
    end
  end

  describe "switch/1 and switch_row/1" do
    test "switch exposes role and aria-checked" do
      on = render(&Controls.switch/1, id: "sw", checked: true)
      off = render(&Controls.switch/1, id: "sw", checked: false)

      assert attr(on, "#sw", "role") == "switch"
      assert attr(on, "#sw", "aria-checked") == "true"
      assert "bg-primary" in classes(on, "#sw")
      assert attr(off, "#sw", "aria-checked") == "false"
      assert "bg-switch-off" in classes(off, "#sw")
    end

    test "switch_row labels the switch and forwards phx-click to it" do
      assigns = %{}

      doc =
        parse(~H"""
        <UI.switch_row
          id="bag"
          title="ใส่ถุงกลับบ้าน"
          subtitle="ชามนี้"
          phx-click="toggle"
        />
        """)

      assert attr(doc, "button#bag", "phx-click") == "toggle"
      assert attr(doc, "button#bag", "aria-labelledby") == "bag-label"
      assert text(doc, "#bag-label") == "ใส่ถุงกลับบ้าน"
      assert text(doc, "small") == "ชามนี้"
    end
  end
end
