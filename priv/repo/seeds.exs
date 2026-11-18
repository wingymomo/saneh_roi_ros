# Dev seed data: the menu from the design handoff (docs/design-handoff/HANDOFF.md §5).
#
# NOTE: this comes from the mockups and still has to be confirmed with the
# shop before it is used for real. Items marked GUESS are not priced in the
# handoff (prices, short names and print-to-kitchen there are placeholders).
#
# The categories themselves are created by a migration.
#
#     mix run priv/repo/seeds.exs
#
# Running it again does nothing once any menu item exists.

alias SanehRoiRos.Menu
alias SanehRoiRos.Repo

if Repo.aggregate(Menu.Item, :count) > 0 do
  IO.puts("Menu already seeded — skipping.")
else
  categories = Map.new(Menu.list_categories(), &{&1.name, &1.id})

  indexed = fn list -> list |> Enum.with_index() |> Map.new(fn {v, i} -> {"#{i}", v} end) end

  group = fn name, opts, options ->
    {:ok, group} =
      Menu.save_option_group(Menu.new_option_group(), %{
        "name" => name,
        "multi" => to_string(Keyword.get(opts, :multi, false)),
        "required" => to_string(Keyword.get(opts, :required, false)),
        "max_select" => Keyword.get(opts, :max_select),
        "options" =>
          indexed.(
            Enum.map(options, fn
              {name, price} -> %{"name" => name, "price_text" => price}
              name -> %{"name" => name}
            end)
          )
      })

    group.id
  end

  item = fn category, name, variants, opts ->
    {:ok, _} =
      Menu.create_item(%{
        "category_id" => categories[category],
        "name" => name,
        "short_names" => opts[:short_names],
        "drink_group" => opts[:drink_group],
        "print_to_kitchen" => Keyword.get(opts, :print, true),
        "price_variants" =>
          indexed.(Enum.map(variants, fn {n, p} -> %{"name" => n, "price" => p} end)),
        "option_group_ids" => Keyword.get(opts, :groups, [])
      })
  end

  # ก๋วยเตี๋ยว
  noodle = group.("เส้น", [required: true], ~w(เส้นเล็ก เส้นใหญ่ เส้นหมี่ขาว บะหมี่ มาม่า วุ้นเส้น))

  meat =
    group.("เนื้อสัตว์", [], ["หมูตุ๋น", "หมูสับ", "หมูหมัก", "หมูแดง", "ไก่ฉีก", {"ทะเล", "40 / 70"}])

  noodle_extra =
    group.("ตัวเลือกอื่น", [multi: true], ["ผักล้วน", "ลูกชิ้นล้วน", {"เพิ่มเส้น+น้ำ", "20"}])

  egg = group.("ไข่", [multi: true], [{"ไข่", "10"}])

  no_add =
    group.("ไม่ใส่", [multi: true], ~w(ไม่ใส่ผัก ไม่ใส่ผักโรย ไม่ใส่ถั่ว ไม่ใส่ถั่วงอก))

  noodle_groups = [noodle, meat, noodle_extra, egg, no_add]

  # GUESS: only "ตก, เรือ" appears in the mockups.
  short = %{"น้ำตก" => "ตก, เรือ", "เย็นตาโฟ" => "เย็น", "เกาเหลา" => "เกา"}

  for name <-
        ~w(น้ำใส น้ำตก น้ำตกต้มยำ ต้มยำ แห้ง แห้งต้มยำ แห้งคลุก เย็นตาโฟ เย็นตาโฟต้มยำ เกาเหลา) do
    item.("ก๋วยเตี๋ยว", name, [{"ธรรมดา", 50}, {"พิเศษ", 60}],
      groups: noodle_groups,
      short_names: short[name]
    )
  end

  # ข้าว
  chicken = group.("ไก่", [required: true], ~w(ไก่ต้ม ไก่ทอด ผสม))
  skin = group.("หนัง", [], ~w(เอาหนัง ไม่เอาหนัง))
  sauce = group.("น้ำจิ้ม", [multi: true], ~w(เต้าเจี้ยว ซีอิ๊วดำ น้ำจิ้มไก่ทอด))
  rice_extra = group.("เพิ่ม", [multi: true], [{"ไข่ต้ม", "10"}, {"ข้าวเพิ่ม", "10"}])

  item.("ข้าว", "ข้าวมันไก่", [{"ธรรมดา", 50}, {"พิเศษ", 60}],
    groups: [chicken, skin, sauce, rice_extra],
    short_names: "มันไก่"
  )

  # GUESS: the handoff prices these per mockup page (0f2–0f8), not reproduced here.
  for name <- ~w(ข้าวหน้าไก่ ข้าวหมูแดง ข้าวขาหมู ข้าวหมูตุ๋น ข้าวยำไก่แซ่บ ข้าวคลุกกะปิ) do
    item.("ข้าว", name, [{"ธรรมดา", 50}, {"พิเศษ", 60}], groups: [rice_extra])
  end

  # กับข้าว
  pork_leg_side = group.("ขาหมู", [multi: true], ~w(เอาหนัง น้ำราดเยอะ))
  item.("กับข้าว", "ขาหมู", [{"เล็ก", 60}, {"ใหญ่", 120}], groups: [pork_leg_side])

  # เพิ่มเติม — GUESS: prices for everything except ลูกชิ้นลวก.
  for name <- ~w(ข้าวสวย ข้าวมัน กากเจียว เกี๊ยวทอด) do
    item.("เพิ่มเติม", name, [{"ธรรมดา", 10}], [])
  end

  item.("เพิ่มเติม", "ลูกชิ้นลวก", [{"30", 30}, {"40", 40}, {"50", 50}], [])

  # เครื่องดื่ม
  for name <-
        ~w(กาแฟ ชาไทย ชาเขียวนม นมชมพู ชามะนาว ชาเขียวมะนาว มะตูม กระเจี๊ยบ โอเลี้ยง อัญชันมะนาว ชาดำเย็น เก็กฮวย) do
    item.("เครื่องดื่ม", name, [{"ขวด", 20}, {"แก้ว", 25}], drink_group: "น้ำชง")
  end

  # GUESS: print: false for water and soft drinks (handed out at the counter).
  item.("เครื่องดื่ม", "น้ำเปล่า", [{"ขวด", 10}], drink_group: "น้ำเปล่า", print: false)

  item.("เครื่องดื่ม", "โค้ก", [{"ขวดแก้ว", 15}, {"กระป๋อง", 16}, {"แก้วใหญ่", 25}],
    drink_group: "น้ำอัดลม",
    print: false
  )

  for name <- ~w(โค้กซีโร่ เป๊ปซี่ แฟนต้าแดง แฟนต้าเขียว สไปรท์) do
    item.("เครื่องดื่ม", name, [{"กระป๋อง", 16}, {"แก้วใหญ่", 25}],
      drink_group: "น้ำอัดลม",
      print: false
    )
  end

  # ไอศกรีม
  cone = group.("ใส่", [required: true], ~w(ถ้วย โคน))
  flavor = group.("รสชาติ", [multi: true], ~w(วานิลลา ช็อกโกแลต สตรอว์เบอร์รี กะทิ ชาไทย เผือก))

  item.("ไอศกรีม", "ไอศกรีมกะทิสด", [{"ราคาต่อลูก", 10}],
    groups: [cone, flavor],
    print: false
  )

  # ขนมถุง
  item.("ขนมถุง", "ขนมถุง", [{"ถุงเล็ก", 30}, {"ถุงใหญ่", 35}], print: false)

  IO.puts("Seeded #{Repo.aggregate(Menu.Item, :count)} menu items.")
end
