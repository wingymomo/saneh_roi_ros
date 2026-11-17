defmodule SanehRoiRosUI.Icon do
  @moduledoc """
  Heroicons (outline, 24px) rendered through the Tailwind heroicons plugin.
  """
  use Phoenix.Component

  @doc ~S"""
  Renders a heroicon by its `hero-*` class name.

      <UI.icon name="hero-chevron-right" class="size-5 text-icon" />
  """
  attr :name, :string, required: true
  attr :class, :any, default: "size-5"
  attr :rest, :global

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, @class]} aria-hidden="true" {@rest} />
    """
  end
end
