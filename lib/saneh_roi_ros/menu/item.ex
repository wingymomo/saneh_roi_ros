defmodule SanehRoiRos.Menu.Item do
  @moduledoc """
  A menu item.

  - `short_names` — comma-separated search aliases ("ตก, เรือ")
  - `drink_group` — section inside the เครื่องดื่ม tab (น้ำชง / น้ำอัดลม /
    น้ำเปล่า); `nil` for other categories
  - `print_to_kitchen` — off for things the front staff hand out themselves
    (ขนมถุง, ไอศกรีม); they still appear on the bill and receipt
  - `sold_out_on` — the shop-local date it was switched to "หมดวันนี้"; the
    item is back on sale automatically the next day
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias SanehRoiRos.Menu.{Category, ItemOptionGroup, OptionGroup, PriceVariant}

  @drink_groups ~w(น้ำชง น้ำอัดลม น้ำเปล่า)

  schema "menu_items" do
    field :name, :string
    field :short_names, :string
    field :drink_group, :string
    field :print_to_kitchen, :boolean, default: true
    field :sold_out_on, :date
    field :position, :integer, default: 0

    belongs_to :category, Category

    has_many :price_variants, PriceVariant,
      foreign_key: :menu_item_id,
      preload_order: [asc: :position],
      on_replace: :delete

    has_many :item_option_groups, ItemOptionGroup,
      foreign_key: :menu_item_id,
      preload_order: [asc: :position],
      on_replace: :delete

    has_many :option_groups, through: [:item_option_groups, :option_group]

    timestamps(type: :utc_datetime)
  end

  def drink_groups, do: @drink_groups

  @doc """
  Changeset for the add/edit form.

  Sizes come in as `price_variants` (with `variants_sort` / `variants_drop`
  for adding and removing rows). Attached option groups come in as
  `option_group_ids`, an ordered list of `OptionGroup` ids.
  """
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:category_id, :name, :short_names, :drink_group, :print_to_kitchen])
    |> update_change(:name, &String.trim/1)
    |> update_change(:short_names, &normalize_short_names/1)
    |> validate_required([:category_id], message: "เลือกหมวด")
    |> validate_required([:name], message: "ต้องกรอกชื่อเมนู")
    |> validate_inclusion(:drink_group, @drink_groups)
    |> cast_assoc(:price_variants,
      with: &PriceVariant.changeset/3,
      sort_param: :variants_sort,
      drop_param: :variants_drop
    )
    |> validate_variants()
    |> put_option_groups(attrs)
    |> assoc_constraint(:category)
  end

  defp normalize_short_names(nil), do: nil

  defp normalize_short_names(text) do
    case text |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == "")) do
      [] -> nil
      names -> Enum.join(names, ", ")
    end
  end

  defp validate_variants(changeset) do
    if get_assoc(changeset, :price_variants, :struct) == [] do
      add_error(changeset, :price_variants, "ต้องมีอย่างน้อย 1 ราคา")
    else
      changeset
    end
  end

  defp put_option_groups(changeset, attrs) do
    case attrs["option_group_ids"] || attrs[:option_group_ids] do
      nil ->
        changeset

      ids ->
        existing =
          case changeset.data.item_option_groups do
            %Ecto.Association.NotLoaded{} -> %{}
            links -> Map.new(links, &{&1.option_group_id, &1})
          end

        links =
          ids
          |> Enum.map(&to_id/1)
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
          |> Enum.with_index()
          |> Enum.map(fn {id, position} ->
            link = Map.get(existing, id, %ItemOptionGroup{option_group_id: id})
            Ecto.Changeset.change(link, position: position)
          end)

        put_assoc(changeset, :item_option_groups, links)
    end
  end

  defp to_id(id) when is_integer(id), do: id
  defp to_id(%OptionGroup{id: id}), do: id

  defp to_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, ""} -> n
      _ -> nil
    end
  end

  def sold_out?(%__MODULE__{sold_out_on: nil}, _today), do: false
  def sold_out?(%__MODULE__{sold_out_on: date}, today), do: Date.compare(date, today) == :eq
end
