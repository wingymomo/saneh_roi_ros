defmodule SanehRoiRosWeb.MenuTag do
  @moduledoc """
  Menu tags with a fixed meaning (app-specific): option-group selection
  rules and "sold out today". Each `kind` brings its own label and picks one
  of the UI kit's tag colours.
  """
  use Phoenix.Component

  @kinds [:required, :single, :multi, :soldout]

  @doc ~S"""
  Menu tag.

  | kind        | label              | colour     |
  |-------------|--------------------|------------|
  | `:required` | ต้องเลือก 1          | `:soft`    |
  | `:single`   | เลือก 1             | `:soft`    |
  | `:multi`    | เลือกได้หลายอย่าง      | `:neutral` |
  | `:soldout`  | หมดวันนี้            | `:accent`  |

      <.menu_tag kind={:soldout} />
  """
  attr :kind, :atom, values: @kinds, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def menu_tag(assigns) do
    ~H"""
    <SanehRoiRosUI.tag variant={kind_variant(@kind)} data-kind={@kind} class={@class} {@rest}>
      {kind_label(@kind)}
    </SanehRoiRosUI.tag>
    """
  end

  @doc "Thai label of a menu tag kind."
  def kind_label(:required), do: "ต้องเลือก 1"
  def kind_label(:single), do: "เลือก 1"
  def kind_label(:multi), do: "เลือกได้หลายอย่าง"
  def kind_label(:soldout), do: "หมดวันนี้"

  @doc "UI kit tag colour used for a kind."
  def kind_variant(:multi), do: :neutral
  def kind_variant(:soldout), do: :accent
  def kind_variant(_required_or_single), do: :soft

  @doc false
  def kinds, do: @kinds
end
