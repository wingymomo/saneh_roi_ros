defmodule SanehRoiRosWeb.ButtonRow do
  @moduledoc """
  Two-button footer row of the app's pages: cancel (secondary) + main action
  (primary). Built on the UI kit's `button`.
  """
  use Phoenix.Component

  @doc ~S"""
  Footer row with two buttons: cancel (secondary, flex 1) + main (primary, flex 2).
  Both are 56px tall so they line up.

  ## Examples

      <.button_row>
        <:secondary phx-click="cancel">ยกเลิก</:secondary>
        <:primary phx-click="save">บันทึก · เพิ่ม ฝน</:primary>
      </.button_row>
  """
  attr :class, :any, default: nil
  attr :rest, :global

  slot :secondary,
    required: true,
    doc: "cancel / secondary action; with `navigate`/`patch`/`href` it renders a link" do
    attr :id, :string
    attr :disabled, :boolean
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :method, :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-disable-with", :string
  end

  slot :primary,
    required: true,
    doc: "main action; with `navigate`/`patch`/`href` it renders a link" do
    attr :id, :string
    attr :disabled, :boolean
    attr :navigate, :string
    attr :patch, :string
    attr :href, :string
    attr :method, :string
    attr :"phx-click", :any
    attr :"phx-target", :any
    attr :"phx-disable-with", :string
    attr :type, :string
  end

  def button_row(assigns) do
    ~H"""
    <div class={["flex gap-2.5", @class]} {@rest}>
      <SanehRoiRosUI.button
        :for={s <- @secondary}
        variant={:secondary}
        size={:lg}
        class="flex-1"
        {slot_attrs(s)}
      >
        {render_slot(s)}
      </SanehRoiRosUI.button>
      <SanehRoiRosUI.button
        :for={p <- @primary}
        variant={:primary}
        size={:lg}
        type={p[:type] || "button"}
        class="flex-[2]"
        {slot_attrs(p)}
      >
        {render_slot(p)}
      </SanehRoiRosUI.button>
    </div>
    """
  end

  defp slot_attrs(slot), do: Map.drop(slot, [:__slot__, :inner_block, :type])
end
