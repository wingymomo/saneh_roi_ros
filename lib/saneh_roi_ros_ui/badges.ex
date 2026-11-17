defmodule SanehRoiRosUI.Badges do
  @moduledoc """
  Small pill tags.
  """
  use Phoenix.Component

  @variants [:primary, :soft, :neutral, :sand, :accent]

  @doc ~S"""
  Small pill tag (22px). `variant` is purely visual; the app decides what
  each one means:

  - `:primary` — solid primary, white text
  - `:soft` — primary tint, primary text
  - `:neutral` — beige, dark-olive text
  - `:sand` — sand, brown text
  - `:accent` — solid brown, white bold text

      <UI.tag variant={:soft}>ต้องเลือก 1</UI.tag>
      <UI.tag variant={:accent}>หมดวันนี้</UI.tag>
  """
  attr :variant, :atom, values: @variants, default: :soft
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def tag(assigns) do
    ~H"""
    <span
      data-variant={@variant}
      class={[
        "inline-flex h-[22px] items-center rounded-full px-2 text-[12px] whitespace-nowrap",
        variant_classes(@variant),
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  defp variant_classes(:primary), do: "bg-primary font-semibold text-white"
  defp variant_classes(:soft), do: "bg-primary-tint font-semibold text-primary"
  defp variant_classes(:neutral), do: "bg-multi font-semibold text-multi-ink"
  defp variant_classes(:sand), do: "bg-sand font-semibold text-brown"
  defp variant_classes(:accent), do: "bg-brown font-bold text-white"

  @doc false
  def variants, do: @variants
end
