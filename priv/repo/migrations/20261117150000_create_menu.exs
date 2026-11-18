defmodule SanehRoiRos.Repo.Migrations.CreateMenu do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string, null: false
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name])

    create table(:menu_items) do
      add :category_id, references(:categories, on_delete: :restrict), null: false
      add :name, :string, null: false
      add :short_names, :string
      add :drink_group, :string
      add :print_to_kitchen, :boolean, null: false, default: true
      add :sold_out_on, :date
      add :position, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:menu_items, [:category_id, :position])

    create table(:price_variants) do
      add :menu_item_id, references(:menu_items, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :price, :integer, null: false
      add :position, :integer, null: false, default: 0
    end

    create index(:price_variants, [:menu_item_id, :position])

    create table(:option_groups) do
      add :name, :string, null: false
      add :multi, :boolean, null: false, default: false
      add :required, :boolean, null: false, default: false
      add :max_select, :integer

      timestamps(type: :utc_datetime)
    end

    create table(:options) do
      add :option_group_id, references(:option_groups, on_delete: :delete_all), null: false
      add :name, :string, null: false
      # Extra price per size, by the size's position on the menu item:
      # [40] = +40 for every size, [40, 70] = +40 first size, +70 second (and later).
      add :price_deltas, {:array, :integer}, null: false, default: [0]
      add :position, :integer, null: false, default: 0
    end

    create index(:options, [:option_group_id, :position])

    create table(:menu_item_option_groups) do
      add :menu_item_id, references(:menu_items, on_delete: :delete_all), null: false
      add :option_group_id, references(:option_groups, on_delete: :delete_all), null: false
      add :position, :integer, null: false, default: 0
    end

    create unique_index(:menu_item_option_groups, [:menu_item_id, :option_group_id])
    create index(:menu_item_option_groups, [:option_group_id])
  end
end
