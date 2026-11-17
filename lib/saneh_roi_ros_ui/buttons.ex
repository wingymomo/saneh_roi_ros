defmodule SanehRoiRosUI.Buttons do
  @moduledoc """
  Buttons.

  Variants: `:primary` (56px, footer CTA), `:secondary`, `:dashed`
  ("+ เพิ่ม…"), `:danger`. Size `:sm` (40px) is used in the top bar.
  """
  use Phoenix.Component

  @variants [:primary, :secondary, :dashed, :danger]

  @doc ~S"""
  Renders a button, or a link when `href`, `navigate` or `patch` is given.

  The primary label should describe the result and the amount, e.g.
  `ส่งครัว + คิดเงิน · 220`.

  ## Examples

      <UI.button variant={:primary} phx-click="send">ส่งครัว + คิดเงิน · 220</UI.button>
      <UI.button variant={:secondary} size={:sm} navigate={~p"/tables/1/move"}>ย้ายโต๊ะ</UI.button>
  """
  attr :variant, :atom, values: @variants, default: :secondary

  attr :size, :atom,
    values: [:lg, :md, :sm],
    default: :md,
    doc: "`:md` = 56px primary / 52px others · `:lg` = 56px for every variant · `:sm` = 40px"

  attr :block, :boolean, default: false, doc: "stretch to the container width"
  attr :type, :string, default: "button"
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(href navigate patch method download name value disabled form replace)

  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    {link?, rest} = SanehRoiRosUI.NavAttrs.split(rest)

    assigns =
      assigns
      |> assign(:classes, button_classes(assigns))
      |> assign(:rest, rest)

    if link? do
      ~H"""
      <.link class={@classes} {@rest}>{render_slot(@inner_block)}</.link>
      """
    else
      ~H"""
      <button type={@type} class={@classes} {@rest}>{render_slot(@inner_block)}</button>
      """
    end
  end

  @doc false
  def button_classes(%{variant: variant, size: size, block: block, class: class}) do
    [
      "inline-flex min-h-11 cursor-pointer select-none items-center justify-center gap-2 px-[18px]",
      "font-semibold transition-[background-color,transform] duration-150 active:scale-[0.98]",
      "disabled:cursor-not-allowed disabled:opacity-50",
      variant_classes(variant),
      size_classes(variant, size),
      block && "w-full",
      class
    ]
  end

  defp variant_classes(:primary),
    do: "border-0 bg-primary font-bold text-white hover:bg-primary-hover active:bg-primary-hover"

  defp variant_classes(:secondary),
    do: "border-[1.5px] border-line bg-surface text-primary hover:bg-white"

  defp variant_classes(:dashed),
    do:
      "border-[1.5px] border-dashed border-line-dashed bg-transparent text-primary hover:bg-surface"

  defp variant_classes(:danger),
    do: "border-[1.5px] border-line bg-surface text-danger hover:bg-white"

  defp size_classes(_variant, :sm), do: "h-10 min-h-10 rounded-sm px-3 text-[14px]"
  defp size_classes(:primary, :lg), do: "h-14 rounded-lg text-[17px]"
  defp size_classes(_variant, :lg), do: "h-14 rounded-lg text-[16px]"
  defp size_classes(:primary, :md), do: "h-14 rounded-lg text-[17px]"
  defp size_classes(:dashed, :md), do: "h-[52px] rounded-lg text-[15px]"
  defp size_classes(_variant, :md), do: "h-[52px] rounded-lg text-[16px]"
end
