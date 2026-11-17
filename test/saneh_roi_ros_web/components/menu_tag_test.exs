defmodule SanehRoiRosWeb.MenuTagTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosWeb.MenuTag

  test "each kind renders its label with its tag colour" do
    for {kind, label, variant} <- [
          {:required, "ต้องเลือก 1", "soft"},
          {:single, "เลือก 1", "soft"},
          {:multi, "เลือกได้หลายอย่าง", "neutral"},
          {:soldout, "หมดวันนี้", "accent"}
        ] do
      doc = render(&MenuTag.menu_tag/1, kind: kind)

      assert text(doc, "span") == label
      assert attr(doc, "span", "data-kind") == Atom.to_string(kind)
      assert attr(doc, "span", "data-variant") == variant
    end
  end

  test "every kind maps to a colour the UI kit offers" do
    for kind <- MenuTag.kinds() do
      assert MenuTag.kind_variant(kind) in SanehRoiRosUI.Badges.variants()
    end
  end
end
