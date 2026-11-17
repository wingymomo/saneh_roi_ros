defmodule SanehRoiRosWeb.LiveSandbox do
  @moduledoc """
  Lets LiveView processes started by browser tests (Wallaby) join the test's
  Ecto sandbox. Only mounted when `config :saneh_roi_ros, sql_sandbox: true`.
  """
  import Phoenix.LiveView
  import Phoenix.Component, only: [assign_new: 3]

  def on_mount(:default, _params, _session, socket) do
    socket =
      assign_new(socket, :phoenix_ecto_sandbox, fn ->
        if connected?(socket), do: get_connect_info(socket, :user_agent)
      end)

    Phoenix.Ecto.SQL.Sandbox.allow(socket.assigns.phoenix_ecto_sandbox, Ecto.Adapters.SQL.Sandbox)
    {:cont, socket}
  end
end
