defmodule SanehRoiRosWeb.RoleTagTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosWeb.RoleTag

  test "each role renders its label with its tag variant" do
    for {role, label, variant, bg} <- [
          {:staff, "พนักงาน", "soft", "bg-primary-tint"},
          {:manager, "ผู้จัดการ", "sand", "bg-sand"},
          {:owner, "เจ้าของ", "primary", "bg-primary"}
        ] do
      doc = render(&RoleTag.role_tag/1, role: role)

      assert text(doc, "span") == label
      assert attr(doc, "span", "data-role") == Atom.to_string(role)
      assert attr(doc, "span", "data-variant") == variant
      assert bg in classes(doc, "span")
    end
  end

  test "role_label/1 and role_variant/1" do
    assert RoleTag.role_label(:manager) == "ผู้จัดการ"
    assert RoleTag.role_variant(:owner) == :primary
    assert RoleTag.roles() == [:staff, :manager, :owner]
  end
end
