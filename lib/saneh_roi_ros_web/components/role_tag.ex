defmodule SanehRoiRosWeb.RoleTag do
  @moduledoc """
  Staff role tag: พนักงาน / ผู้จัดการ / เจ้าของ (app-specific: knows the
  roles). Rendered with the UI kit's `tag`.
  """
  use Phoenix.Component

  @roles [:staff, :manager, :owner]

  @doc ~S"""
  Role tag.

      <.role_tag role={:manager} />
  """
  attr :role, :atom, values: @roles, required: true
  attr :class, :any, default: nil
  attr :rest, :global

  def role_tag(assigns) do
    ~H"""
    <SanehRoiRosUI.tag variant={role_variant(@role)} data-role={@role} class={@class} {@rest}>
      {role_label(@role)}
    </SanehRoiRosUI.tag>
    """
  end

  @doc "Thai label of a role."
  def role_label(:staff), do: "พนักงาน"
  def role_label(:manager), do: "ผู้จัดการ"
  def role_label(:owner), do: "เจ้าของ"

  @doc "Tag variant used for a role."
  def role_variant(:staff), do: :soft
  def role_variant(:manager), do: :sand
  def role_variant(:owner), do: :primary

  @doc false
  def roles, do: @roles
end
