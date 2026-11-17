defmodule SanehRoiRosWeb.CategoryTabsTest do
  use SanehRoiRosUI.ComponentCase, async: true

  alias SanehRoiRosWeb.CategoryTabs

  describe "category_tabs/1" do
    test "renders the 7 fixed categories in order with the active one pressed" do
      doc = render(&CategoryTabs.category_tabs/1, id: "tabs", active: "กับข้าว", on_select: "cat")

      labels = doc |> q("#tabs button") |> Enum.map(&String.trim(LazyHTML.text(&1)))
      assert labels == ~w(ก๋วยเตี๋ยว ข้าว กับข้าว เพิ่มเติม เครื่องดื่ม ไอศกรีม ขนมถุง)

      assert attr(doc, "#tabs-2", "aria-pressed") == "true"
      assert attr(doc, "#tabs-0", "aria-pressed") == "false"
      assert attr(doc, "#tabs-2", "phx-click") == "cat"
      assert attr(doc, "#tabs-2", "phx-value-category") == "กับข้าว"
    end

    test "is wired to the CategoryTabs hook" do
      doc = render(&CategoryTabs.category_tabs/1, id: "tabs", threshold: 60)

      assert attr(doc, "#tabs", "phx-hook") =~ "CategoryTabs"
      assert attr(doc, "#tabs", "data-threshold") == "60"
      # expanded by default; compact mode is only ever set by the hook
      assert attr(doc, "#tabs", "data-compact") == nil
    end
  end

  test "categories/0 is the fixed display order" do
    assert CategoryTabs.categories() == ~w(ก๋วยเตี๋ยว ข้าว กับข้าว เพิ่มเติม เครื่องดื่ม ไอศกรีม ขนมถุง)
  end
end
