defmodule SanehRoiRos.Menu.OptionGroup do
  @moduledoc """
  A set of choices asked when ordering (เส้น, เนื้อสัตว์, ไม่ใส่, …).

  Groups are shared: one group (e.g. เส้น) is attached to many menu items, so
  editing it changes every item that uses it.

  - `multi: false` — choose one (radio); `multi: true` — choose several
  - `required` — must choose before the item can be added
  - `max_select` — upper limit for `multi` groups (`nil` = no limit)
  """
  use Ecto.Schema
  import Ecto.Changeset

  alias SanehRoiRos.Menu.Option

  schema "option_groups" do
    field :name, :string
    field :multi, :boolean, default: false
    field :required, :boolean, default: false
    field :max_select, :integer

    has_many :options, Option, preload_order: [asc: :position], on_replace: :delete

    has_many :item_option_groups, SanehRoiRos.Menu.ItemOptionGroup

    timestamps(type: :utc_datetime)
  end

  def changeset(group, attrs) do
    group
    |> cast(attrs, [:name, :multi, :required, :max_select])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name], message: "ต้องกรอกชื่อ")
    |> validate_number(:max_select, greater_than: 0)
    |> cast_assoc(:options,
      with: &Option.changeset/3,
      sort_param: :options_sort,
      drop_param: :options_drop
    )
    |> validate_options()
    |> clear_max_select_unless_multi()
  end

  defp validate_options(changeset) do
    options = get_assoc(changeset, :options, :struct)

    if options == [] do
      add_error(changeset, :options, "ต้องมีอย่างน้อย 1 ตัวเลือก")
    else
      changeset
    end
  end

  defp clear_max_select_unless_multi(changeset) do
    if get_field(changeset, :multi), do: changeset, else: put_change(changeset, :max_select, nil)
  end

  @doc """
  Selection kind shown as a tag: `:required` (ต้องเลือก 1), `:single`
  (เลือก 1) or `:multi` (เลือกได้หลายอย่าง).
  """
  def selection(%{multi: true}), do: :multi
  def selection(%{required: true}), do: :required
  def selection(_), do: :single
end
