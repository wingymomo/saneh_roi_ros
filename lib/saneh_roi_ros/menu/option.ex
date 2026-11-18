defmodule SanehRoiRos.Menu.Option do
  @moduledoc """
  One choice in an option group (เส้นเล็ก, ทะเล, ไม่ใส่ผัก, …).

  `price_deltas` is the extra price by the size's position on the menu item:
  `[0]` = free, `[40]` = +40 for every size, `[40, 70]` = +40 on the first
  size and +70 on the second (and any later) size — e.g. ทะเล turns
  ธรรมดา 50 / พิเศษ 60 into 90 / 130.

  In forms the deltas are edited as text (`price_text`): `"40"` or `"40 / 70"`.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "options" do
    field :name, :string
    field :price_deltas, {:array, :integer}, default: [0]
    field :price_text, :string, virtual: true
    field :position, :integer, default: 0

    belongs_to :option_group, SanehRoiRos.Menu.OptionGroup
  end

  def changeset(option, attrs, position) do
    option
    |> cast(attrs, [:name, :price_deltas, :price_text])
    |> put_change(:position, position)
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name], message: "ต้องกรอก")
    |> parse_price_text()
  end

  defp parse_price_text(changeset) do
    case get_change(changeset, :price_text) do
      nil ->
        changeset

      text ->
        case parse_deltas(text) do
          {:ok, deltas} -> put_change(changeset, :price_deltas, deltas)
          :error -> add_error(changeset, :price_text, "ใส่ตัวเลข เช่น 40 หรือ 40 / 70")
        end
    end
  end

  @doc """
  Parses `"40"`, `"+40 / +70"` or `""` (free).

      iex> SanehRoiRos.Menu.Option.parse_deltas("+40 / 70")
      {:ok, [40, 70]}
      iex> SanehRoiRos.Menu.Option.parse_deltas("")
      {:ok, [0]}
      iex> SanehRoiRos.Menu.Option.parse_deltas("abc")
      :error
  """
  def parse_deltas(text) do
    parts =
      text
      |> String.split("/")
      |> Enum.map(&(&1 |> String.trim() |> String.trim_leading("+")))

    case parts do
      [""] ->
        {:ok, [0]}

      parts ->
        Enum.reduce_while(parts, {:ok, []}, fn part, {:ok, acc} ->
          case Integer.parse(part) do
            {n, ""} -> {:cont, {:ok, acc ++ [n]}}
            _ -> {:halt, :error}
          end
        end)
    end
  end

  @doc """
  Deltas as edited in forms.

      iex> SanehRoiRos.Menu.Option.format_deltas([40, 70])
      "40 / 70"
      iex> SanehRoiRos.Menu.Option.format_deltas([0])
      "0"
  """
  def format_deltas(deltas), do: Enum.map_join(deltas, " / ", &Integer.to_string/1)

  @doc "Extra price of `option` on the size at `variant_index` (0-based)."
  def delta(%__MODULE__{price_deltas: deltas}, variant_index) do
    Enum.at(deltas, variant_index) || List.last(deltas) || 0
  end

  @doc """
  Short price label shown next to the option name, or `nil` when free.

      iex> SanehRoiRos.Menu.Option.price_label(%SanehRoiRos.Menu.Option{price_deltas: [40, 70]})
      "+40 / +70"
      iex> SanehRoiRos.Menu.Option.price_label(%SanehRoiRos.Menu.Option{price_deltas: [0]})
      nil
  """
  def price_label(%__MODULE__{price_deltas: deltas}) do
    if Enum.all?(deltas, &(&1 == 0)) do
      nil
    else
      Enum.map_join(deltas, " / ", fn
        d when d >= 0 -> "+#{d}"
        d -> Integer.to_string(d)
      end)
    end
  end
end
