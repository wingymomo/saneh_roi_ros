defmodule SanehRoiRos.Menu do
  @moduledoc """
  Menu: categories, items with their sizes/prices, and shared option groups.

  "หมดวันนี้" is stored as the shop-local date (`today/0`, Asia/Bangkok); the
  item is on sale again automatically from the next day. Functions that
  depend on the date take an optional `today` so tests can pin it.
  """
  import Ecto.Query

  alias SanehRoiRos.Repo
  alias SanehRoiRos.Menu.{Category, Item, ItemOptionGroup, Option, OptionGroup, PriceVariant}

  # Thailand has no daylight saving time, so a fixed offset is exact.
  @shop_utc_offset 7 * 60 * 60

  @doc "Today's date at the shop (UTC+7)."
  def today(now \\ DateTime.utc_now()) do
    now |> DateTime.add(@shop_utc_offset, :second) |> DateTime.to_date()
  end

  # ---------------------------------------------------------------- categories

  @doc "All categories in display order."
  def list_categories do
    Repo.all(from c in Category, order_by: [c.position, c.id])
  end

  def get_category!(id), do: Repo.get!(Category, id)

  def create_category(attrs) do
    %Category{} |> Category.changeset(attrs) |> Repo.insert()
  end

  # ---------------------------------------------------------------- items

  @doc """
  Items of a category (or every item when `category_id` is `nil`), in display
  order, with sizes and option groups preloaded.

  Options:

    * `:search` — matches the name or a short name, case-insensitive
  """
  def list_items(category_id, opts \\ []) do
    Item
    |> filter_category(category_id)
    |> filter_search(opts[:search])
    |> order_by([i], [i.position, i.id])
    |> preload(^item_preloads())
    |> Repo.all()
  end

  defp filter_category(query, nil), do: query
  defp filter_category(query, id), do: where(query, [i], i.category_id == ^id)

  defp filter_search(query, nil), do: query

  defp filter_search(query, search) do
    case String.trim(search) do
      "" ->
        query

      term ->
        pattern = "%" <> escape_like(term) <> "%"

        where(
          query,
          [i],
          ilike(i.name, ^pattern) or ilike(coalesce(i.short_names, ""), ^pattern)
        )
    end
  end

  defp escape_like(term), do: String.replace(term, ~r/[\\%_]/, "\\\\\\0")

  @doc "Number of items on sale and sold out today, across the whole menu."
  def status_counts(today \\ today()) do
    sold_out = Repo.aggregate(from(i in Item, where: i.sold_out_on == ^today), :count)
    total = Repo.aggregate(Item, :count)
    %{on_sale: total - sold_out, sold_out: sold_out}
  end

  @doc "Number of items in each category, as `%{category_id => count}`."
  def item_counts_by_category do
    from(i in Item, group_by: i.category_id, select: {i.category_id, count(i.id)})
    |> Repo.all()
    |> Map.new()
  end

  def get_item!(id), do: Item |> Repo.get!(id) |> Repo.preload(item_preloads())

  defp item_preloads do
    [
      :category,
      price_variants: from(v in PriceVariant, order_by: v.position),
      item_option_groups:
        {from(l in ItemOptionGroup, order_by: l.position),
         option_group: [options: from(o in Option, order_by: o.position)]}
    ]
  end

  @doc "A new item for the add form: one empty size row, in `category_id`."
  def new_item(category_id \\ nil) do
    %Item{
      category_id: category_id,
      price_variants: [%PriceVariant{name: "ธรรมดา"}],
      item_option_groups: []
    }
  end

  def change_item(%Item{} = item, attrs \\ %{}), do: Item.changeset(item, attrs)

  def create_item(attrs) do
    %Item{item_option_groups: []}
    |> Item.changeset(attrs)
    |> put_next_position()
    |> Repo.insert()
    |> reload_item()
  end

  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
    |> reload_item()
  end

  defp reload_item({:ok, item}), do: {:ok, get_item!(item.id)}
  defp reload_item(error), do: error

  defp put_next_position(changeset) do
    case Ecto.Changeset.get_field(changeset, :category_id) do
      nil ->
        changeset

      category_id ->
        max =
          Repo.one(from i in Item, where: i.category_id == ^category_id, select: max(i.position))

        Ecto.Changeset.put_change(changeset, :position, (max || -1) + 1)
    end
  end

  @doc """
  Switches an item between on sale and "หมดวันนี้" (until the end of `today`).
  """
  def set_sold_out(%Item{} = item, sold_out?, today \\ today()) do
    item
    |> Ecto.Changeset.change(sold_out_on: if(sold_out?, do: today))
    |> Repo.update()
  end

  defdelegate sold_out?(item, today), to: Item

  # ---------------------------------------------------------------- option groups

  @doc "All option groups (with options), by name."
  def list_option_groups do
    Repo.all(
      from g in OptionGroup,
        order_by: [g.name, g.id],
        preload: [options: ^from(o in Option, order_by: o.position)]
    )
  end

  def get_option_group!(id) do
    OptionGroup
    |> Repo.get!(id)
    |> Repo.preload(options: from(o in Option, order_by: o.position))
  end

  @doc "A new option group with no options."
  def new_option_group, do: %OptionGroup{options: []}

  def change_option_group(%OptionGroup{} = group, attrs \\ %{}) do
    OptionGroup.changeset(group, attrs)
  end

  @doc "Inserts or updates an option group (shared by every item that uses it)."
  def save_option_group(%OptionGroup{} = group, attrs) do
    group
    |> OptionGroup.changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, group} -> {:ok, get_option_group!(group.id)}
      error -> error
    end
  end

  @doc "Number of menu items using the option group."
  def option_group_usage(%OptionGroup{id: nil}), do: 0

  def option_group_usage(%OptionGroup{id: id}) do
    Repo.aggregate(from(l in ItemOptionGroup, where: l.option_group_id == ^id), :count)
  end

  # ---------------------------------------------------------------- prices

  @doc """
  Unit price of `item` in size `variant` with the chosen `options`.

  Each option is an `%Option{}` or `{%Option{}, quantity}` (e.g. 3 eggs).
  An option's extra price depends on the size's position (see `Option`).
  """
  def unit_price(%Item{price_variants: variants}, %PriceVariant{} = variant, options \\ []) do
    index = Enum.find_index(variants, &(&1.id == variant.id)) || 0

    Enum.reduce(options, variant.price, fn
      {%Option{} = option, qty}, total -> total + Option.delta(option, index) * qty
      %Option{} = option, total -> total + Option.delta(option, index)
    end)
  end

  @doc """
  Price summary shown under an item in the menu list, e.g.
  `"50 / 60 · ทะเล 90 / 130"`: the size prices, then each priced choice of a
  single-choice group as full prices.
  """
  def price_summary(%Item{price_variants: variants} = item) do
    base = Enum.map_join(variants, " / ", &Integer.to_string(&1.price))

    priced =
      for %{option_group: %OptionGroup{multi: false} = group} <-
            item.item_option_groups,
          option <- group.options,
          Option.price_label(option) do
        prices =
          variants
          |> Enum.with_index()
          |> Enum.map_join(" / ", fn {v, i} ->
            Integer.to_string(v.price + Option.delta(option, i))
          end)

        "#{option.name} #{prices}"
      end

    Enum.join([base | priced], " · ")
  end
end
