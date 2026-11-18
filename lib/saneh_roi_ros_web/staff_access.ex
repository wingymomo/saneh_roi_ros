defmodule SanehRoiRosWeb.StaffAccess do
  @moduledoc """
  Who is using the app, and what their role may open.

  **Stub:** there is no staff login yet (screens 00 / 00c–00e). Until there is,
  the role comes from the session key `"staff_role"` (tests set it) and
  defaults to `:owner`. Replace `current_role/1` once login exists; the role
  checks below stay as they are.

      live_session :menu, on_mount: [{SanehRoiRosWeb.StaffAccess, :menu}] do
        live "/menu", MenuLive.Index
      end
  """
  import Phoenix.Component, only: [assign: 3]
  import Phoenix.LiveView, only: [put_flash: 3, redirect: 2]

  alias SanehRoiRosWeb.MainNav

  @roles %{"staff" => :staff, "manager" => :manager, "owner" => :owner}

  @doc false
  def on_mount(:default, _params, session, socket) do
    {:cont, assign(socket, :current_role, current_role(session))}
  end

  # Pages behind a bottom-nav item (`:menu`, `:sales`, …) use the nav's permissions.
  def on_mount(item, _params, session, socket) when is_atom(item) do
    role = current_role(session)
    socket = assign(socket, :current_role, role)

    if MainNav.allowed?(role, item) do
      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, MainNav.denied_message(item))
       |> redirect(to: "/")}
    end
  end

  defp current_role(session) do
    Map.get(@roles, session["staff_role"], :owner)
  end
end
