defmodule SanehRoiRosWeb.OptionGroupRowTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosWeb.OptionGroupRow

  describe "option_group_row/1" do
    test "shows name, selection tag and joined options" do
      doc =
        render(&OptionGroupRow.option_group_row/1,
          id: "g",
          name: "เส้น",
          selection: :required,
          options: ["เส้นเล็ก", "เส้นใหญ่"],
          "phx-click": "edit"
        )

      assert attr(doc, "button#g", "phx-click") == "edit"
      assert text(doc, "#g [data-kind=required]") == "ต้องเลือก 1"
      assert attr(doc, "#g [data-kind]", "data-variant") == "soft"
      assert text(doc, "#g") =~ "เส้นเล็ก · เส้นใหญ่"
    end

    test "single and multi labels" do
      single = render(&OptionGroupRow.option_group_row/1, name: "ขนาด", selection: :single)

      multi =
        render(&OptionGroupRow.option_group_row/1,
          name: "ไม่ใส่",
          selection: :multi,
          navigate: "/g"
        )

      assert text(single, "[data-kind=single][data-variant=soft]") == "เลือก 1"
      assert text(multi, "[data-kind=multi][data-variant=neutral]") == "เลือกได้หลายอย่าง"
      assert has?(multi, "a[href='/g']")
    end
  end

  test "a disabled row with navigate is a disabled button" do
    doc =
      render(&OptionGroupRow.option_group_row/1,
        id: "g",
        name: "เส้น",
        selection: :required,
        navigate: "/g",
        disabled: true
      )

    assert has?(doc, "button#g[disabled]")
    refute has?(doc, "a")
  end
end
