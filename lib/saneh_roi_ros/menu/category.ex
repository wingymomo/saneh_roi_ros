defmodule SanehRoiRos.Menu.Category do
  @moduledoc "Menu category (ก๋วยเตี๋ยว, ข้าว, …), shown as tabs in display order."
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :position, :integer, default: 0

    has_many :items, SanehRoiRos.Menu.Item

    timestamps(type: :utc_datetime)
  end

  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :position])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
