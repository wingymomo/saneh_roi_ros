defmodule SanehRoiRos.Repo.Migrations.InsertMenuCategories do
  use Ecto.Migration

  # The seven fixed categories, in tab order (DESIGN_SYSTEM.md §2.3).
  # There is no screen to add categories yet ("+ เพิ่มหมวดใหม่" is still open).
  @categories ~w(ก๋วยเตี๋ยว ข้าว กับข้าว เพิ่มเติม เครื่องดื่ม ไอศกรีม ขนมถุง)

  def up do
    for {name, position} <- Enum.with_index(@categories) do
      execute("""
      INSERT INTO categories (name, position, inserted_at, updated_at)
      VALUES ('#{name}', #{position}, now(), now())
      ON CONFLICT (name) DO NOTHING
      """)
    end
  end

  def down do
    names = Enum.map_join(@categories, ", ", &"'#{&1}'")

    execute(
      "DELETE FROM categories WHERE name IN (#{names}) AND NOT EXISTS (SELECT 1 FROM menu_items WHERE menu_items.category_id = categories.id)"
    )
  end
end
