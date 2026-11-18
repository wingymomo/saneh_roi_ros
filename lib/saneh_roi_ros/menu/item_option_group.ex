defmodule SanehRoiRos.Menu.ItemOptionGroup do
  @moduledoc "Join: an option group attached to a menu item, in display order."
  use Ecto.Schema

  schema "menu_item_option_groups" do
    field :position, :integer, default: 0

    belongs_to :menu_item, SanehRoiRos.Menu.Item
    belongs_to :option_group, SanehRoiRos.Menu.OptionGroup
  end
end
