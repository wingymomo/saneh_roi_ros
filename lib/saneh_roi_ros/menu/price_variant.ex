defmodule SanehRoiRos.Menu.PriceVariant do
  @moduledoc """
  A size and its price (ธรรมดา 50, พิเศษ 60, ขวด 20, …). Every menu item has
  at least one. The name may be the price itself (ลูกชิ้นลวก 30 / 40 / 50).
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "price_variants" do
    field :name, :string
    field :price, :integer
    field :position, :integer, default: 0

    belongs_to :menu_item, SanehRoiRos.Menu.Item
  end

  def changeset(variant, attrs, position) do
    variant
    |> cast(attrs, [:name, :price])
    |> put_change(:position, position)
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name, :price], message: "ต้องกรอก")
    |> validate_number(:price, greater_than_or_equal_to: 0, message: "ราคาต้องไม่ติดลบ")
  end
end
