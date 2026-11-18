defmodule SanehRoiRos.MenuFixtures do
  @moduledoc "Test helpers for the menu (data loosely based on the design handoff)."

  alias SanehRoiRos.Menu

  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{name: "หมวด#{System.unique_integer([:positive])}", position: 0})
      |> Menu.create_category()

    category
  end

  def option_group_fixture(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        "name" => "เส้น",
        "multi" => "false",
        "required" => "true",
        "options" => %{
          "0" => %{"name" => "เส้นเล็ก"},
          "1" => %{"name" => "เส้นใหญ่"}
        }
      })

    {:ok, group} = Menu.save_option_group(Menu.new_option_group(), attrs)
    group
  end

  def item_fixture(attrs \\ %{}) do
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
    category_id = attrs["category_id"] || category_fixture().id

    {:ok, item} =
      attrs
      |> Enum.into(%{
        "category_id" => category_id,
        "name" => "น้ำตก",
        "price_variants" => %{
          "0" => %{"name" => "ธรรมดา", "price" => "50"},
          "1" => %{"name" => "พิเศษ", "price" => "60"}
        }
      })
      |> Menu.create_item()

    item
  end
end
