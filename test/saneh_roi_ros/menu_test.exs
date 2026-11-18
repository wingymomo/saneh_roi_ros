defmodule SanehRoiRos.MenuTest do
  use SanehRoiRos.DataCase, async: true

  import SanehRoiRos.MenuFixtures

  alias SanehRoiRos.Menu
  alias SanehRoiRos.Menu.{Item, Option}

  doctest SanehRoiRos.Menu.Option

  describe "today/1" do
    test "uses the shop's UTC+7 date" do
      assert Menu.today(~U[2026-11-17 16:59:59Z]) == ~D[2026-11-17]
      assert Menu.today(~U[2026-11-17 17:00:00Z]) == ~D[2026-11-18]
    end
  end

  describe "items" do
    test "create_item/1 stores sizes in order and a position at the end of its category" do
      category = category_fixture()
      first = item_fixture(category_id: category.id)
      second = item_fixture(category_id: category.id, name: "น้ำใส")

      assert [%{name: "ธรรมดา", price: 50, position: 0}, %{name: "พิเศษ", price: 60, position: 1}] =
               first.price_variants

      assert second.position == first.position + 1
    end

    test "create_item/1 needs a name and at least one size" do
      category = category_fixture()

      assert {:error, changeset} =
               Menu.create_item(%{"category_id" => category.id, "name" => " "})

      assert %{name: [_], price_variants: [_]} = errors_on(changeset)
    end

    test "create_item/1 normalises short names" do
      item = item_fixture(short_names: " ตก ,เรือ, ")
      assert item.short_names == "ตก, เรือ"
    end

    test "update_item/2 drops and reorders sizes" do
      item = item_fixture()
      [small, large] = item.price_variants

      {:ok, item} =
        Menu.update_item(item, %{
          "price_variants" => %{
            "0" => %{"id" => small.id, "name" => "ธรรมดา", "price" => "50"},
            "1" => %{"id" => large.id, "name" => "พิเศษ", "price" => "65"},
            "2" => %{"name" => "จัมโบ้", "price" => "80"}
          },
          "variants_sort" => ["2", "0", "1"],
          "variants_drop" => ["0"]
        })

      assert Enum.map(item.price_variants, &{&1.name, &1.price}) == [
               {"จัมโบ้", 80},
               {"พิเศษ", 65}
             ]
    end

    test "attaches shared option groups in the given order" do
      noodle = option_group_fixture(%{"name" => "เส้น"})
      meat = option_group_fixture(%{"name" => "เนื้อสัตว์"})

      item = item_fixture(option_group_ids: [meat.id, noodle.id])
      assert Enum.map(item.item_option_groups, & &1.option_group.name) == ["เนื้อสัตว์", "เส้น"]

      other = item_fixture(option_group_ids: [noodle.id])
      assert Menu.option_group_usage(noodle) == 2

      {:ok, item} = Menu.update_item(item, %{"option_group_ids" => [to_string(noodle.id)]})
      assert Enum.map(item.item_option_groups, & &1.option_group.name) == ["เส้น"]
      assert Menu.option_group_usage(meat) == 0
      assert other.item_option_groups |> length() == 1
    end

    test "list_items/2 filters by category and search on name or short name" do
      noodles = category_fixture()
      rice = category_fixture()
      item_fixture(category_id: noodles.id, name: "น้ำตก", short_names: "เรือ")
      item_fixture(category_id: noodles.id, name: "เย็นตาโฟ")
      item_fixture(category_id: rice.id, name: "ข้าวมันไก่")

      assert noodles.id |> Menu.list_items() |> Enum.map(& &1.name) == ["น้ำตก", "เย็นตาโฟ"]
      assert Menu.list_items(nil, search: "เรือ") |> Enum.map(& &1.name) == ["น้ำตก"]
      assert Menu.list_items(nil, search: "ข้าว") |> Enum.map(& &1.name) == ["ข้าวมันไก่"]
      assert Menu.list_items(nil, search: "%") == []
    end
  end

  describe "sold out" do
    test "is sold out only on the day it was switched off" do
      item = item_fixture()
      {:ok, item} = Menu.set_sold_out(item, true, ~D[2026-11-17])

      assert Item.sold_out?(item, ~D[2026-11-17])
      refute Item.sold_out?(item, ~D[2026-11-18])

      assert %{sold_out: 1} = Menu.status_counts(~D[2026-11-17])
      assert %{sold_out: 0} = Menu.status_counts(~D[2026-11-18])

      {:ok, item} = Menu.set_sold_out(item, false, ~D[2026-11-17])
      refute Item.sold_out?(item, ~D[2026-11-17])
    end
  end

  describe "option groups" do
    test "save_option_group/2 parses per-size prices" do
      group =
        option_group_fixture(%{
          "name" => "เนื้อสัตว์",
          "options" => %{
            "0" => %{"name" => "หมูตุ๋น", "price_text" => ""},
            "1" => %{"name" => "ทะเล", "price_text" => "+40 / +70"}
          }
        })

      assert [%{name: "หมูตุ๋น", price_deltas: [0]}, %{name: "ทะเล", price_deltas: [40, 70]}] =
               group.options
    end

    test "rejects bad prices and an empty group" do
      assert {:error, changeset} =
               Menu.save_option_group(Menu.new_option_group(), %{
                 "name" => "ไข่",
                 "options" => %{"0" => %{"name" => "ไข่ต้ม", "price_text" => "สิบ"}}
               })

      assert %{options: [%{price_text: [_]}]} = errors_on(changeset)

      assert {:error, changeset} =
               Menu.save_option_group(Menu.new_option_group(), %{"name" => "ว่าง"})

      assert %{options: [_]} = errors_on(changeset)
    end

    test "max_select only applies to multi-choice groups" do
      group = option_group_fixture(%{"multi" => "false", "max_select" => "2"})
      assert group.max_select == nil

      group = option_group_fixture(%{"multi" => "true", "max_select" => "2"})
      assert group.max_select == 2
    end
  end

  describe "prices" do
    setup do
      meat =
        option_group_fixture(%{
          "name" => "เนื้อสัตว์",
          "options" => %{
            "0" => %{"name" => "หมูตุ๋น"},
            "1" => %{"name" => "ทะเล", "price_text" => "40 / 70"}
          }
        })

      extra =
        option_group_fixture(%{
          "name" => "เพิ่ม",
          "multi" => "true",
          "required" => "false",
          "options" => %{"0" => %{"name" => "ไข่", "price_text" => "10"}}
        })

      item = item_fixture(option_group_ids: [meat.id, extra.id])
      %{item: item, seafood: Enum.at(meat.options, 1), egg: hd(extra.options)}
    end

    test "ทะเล turns 50 / 60 into 90 / 130", %{item: item, seafood: seafood} do
      [regular, special] = item.price_variants
      assert Menu.unit_price(item, regular, [seafood]) == 90
      assert Menu.unit_price(item, special, [seafood]) == 130
    end

    test "ทะเล + 3 eggs on พิเศษ", %{item: item, seafood: seafood, egg: egg} do
      [_regular, special] = item.price_variants
      assert Menu.unit_price(item, special, [seafood, {egg, 3}]) == 160
    end

    test "price_summary/1 lists sizes and priced required choices", %{item: item} do
      assert Menu.price_summary(item) == "50 / 60 · ทะเล 90 / 130"
    end

    test "a single delta applies to every size" do
      option = %Option{price_deltas: [20]}
      assert Option.delta(option, 0) == 20
      assert Option.delta(option, 3) == 20
    end
  end
end
