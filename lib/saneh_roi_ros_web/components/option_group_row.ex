defmodule SanehRoiRosWeb.OptionGroupRow do
  @moduledoc """
  Option group row on the add/edit menu page (app-specific: knows the menu
  option-group selection rules).
  """
  use Phoenix.Component

  import SanehRoiRosWeb.MenuTag, only: [menu_tag: 1]

  @doc ~S"""
  Option group row (add/edit menu page): group name + selection tag, the
  options joined by ` · `, and a chevron.

  `selection` (`:required`, `:single`, `:multi`) is shown with
  `SanehRoiRosWeb.MenuTag`.

      <.option_group_row id="group-noodle" name="เส้น" selection={:required}
        options={["เส้นเล็ก", "เส้นใหญ่"]} phx-click="edit_group" phx-value-id="noodle" />
  """
  attr :id, :string, default: nil
  attr :name, :string, required: true
  attr :selection, :atom, values: [:required, :single, :multi], required: true
  attr :options, :list, default: []
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch disabled)

  def option_group_row(%{rest: rest} = assigns) do
    {link?, rest} = SanehRoiRosUI.NavAttrs.split(rest)
    assigns = assign(assigns, link?: link?, rest: rest)

    ~H"""
    <.link :if={@link?} id={@id} class={option_group_class(@class)} {@rest}>
      <.option_group_content name={@name} selection={@selection} options={@options} />
    </.link>
    <button :if={!@link?} id={@id} type="button" class={option_group_class(@class)} {@rest}>
      <.option_group_content name={@name} selection={@selection} options={@options} />
    </button>
    """
  end

  defp option_group_class(extra) do
    [
      "flex w-full cursor-pointer items-center gap-3 rounded-xl border-[1.5px] border-line-soft bg-surface",
      "py-3.5 pr-3 pl-4 text-left text-primary transition-colors duration-150 hover:bg-white",
      extra
    ]
  end

  attr :name, :string, required: true
  attr :selection, :atom, required: true
  attr :options, :list, required: true

  defp option_group_content(assigns) do
    ~H"""
    <span class="flex min-w-0 flex-1 flex-col gap-1">
      <span class="flex items-center gap-2 text-[16px] font-bold">
        {@name}
        <.menu_tag kind={@selection} />
      </span>
      <span class="text-[14px] text-muted">{Enum.join(@options, " · ")}</span>
    </span>
    <SanehRoiRosUI.icon name="hero-chevron-right" class="size-5 flex-none text-icon" />
    """
  end
end
