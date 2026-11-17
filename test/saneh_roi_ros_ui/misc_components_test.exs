defmodule SanehRoiRosUI.MiscComponentsTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosUI.{Badges, Form, Icon}

  describe "tag/1" do
    test "each variant has its own colours" do
      for {variant, bg} <- [
            primary: "bg-primary",
            soft: "bg-primary-tint",
            neutral: "bg-multi",
            sand: "bg-sand",
            accent: "bg-brown"
          ] do
        doc = render(&Badges.tag/1, variant: variant, inner_block: slot("x"))
        assert attr(doc, "span", "data-variant") == Atom.to_string(variant)
        assert bg in classes(doc, "span")
      end
    end

    test "defaults to soft" do
      assigns = %{}
      doc = parse(~H|<UI.tag id="t">ต้องเลือก 1</UI.tag>|)
      assert attr(doc, "#t", "data-variant") == "soft"
    end
  end

  describe "input/1" do
    test "renders label, value and hint from a form field" do
      form = Phoenix.Component.to_form(%{"customer" => "พี่แดง"}, as: :takeaway)
      doc = render(&Form.input/1, field: form[:customer], label: "ชื่อลูกค้า", hint: "ไม่บังคับ")

      assert attr(doc, "input", "id") == "takeaway_customer"
      assert attr(doc, "input", "name") == "takeaway[customer]"
      assert attr(doc, "input", "value") == "พี่แดง"
      assert attr(doc, "label", "for") == "takeaway_customer"
      assert text(doc, "small") == "ไม่บังคับ"
    end

    test "shows errors instead of the hint once the field is used" do
      form =
        Phoenix.Component.to_form(%{"customer" => ""},
          as: :takeaway,
          errors: [customer: {"ต้องมีอย่างน้อย %{count} ตัว", [count: 2]}],
          action: :validate
        )

      doc = render(&Form.input/1, field: form[:customer], hint: "ไม่บังคับ")

      assert attr(doc, "input", "aria-invalid") == "true"
      assert text(doc, "small") == "ต้องมีอย่างน้อย 2 ตัว"
      assert "border-danger" in classes(doc, "input")
    end

    test "select" do
      doc =
        render(&Form.input/1,
          id: "role",
          name: "role",
          type: "select",
          value: "manager",
          options: [{"พนักงาน", "staff"}, {"ผู้จัดการ", "manager"}]
        )

      assert has?(doc, "select#role option[value=manager][selected]")
      # native arrow hidden, our chevron drawn instead
      assert "appearance-none" in classes(doc, "select#role")
      assert has?(doc, ".hero-chevron-down")
    end
  end

  test "icon renders a hero class span" do
    doc = render(&Icon.icon/1, name: "hero-plus", class: "size-4")
    assert classes(doc, "span") == ["hero-plus", "size-4"]
    assert attr(doc, "span", "aria-hidden") == "true"
  end
end
