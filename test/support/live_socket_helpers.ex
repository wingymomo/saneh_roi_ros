defmodule SanehRoiRosWeb.LiveSocketHelpers do
  @moduledoc """
  Builds a bare LiveView socket and runs `on_mount` hooks on it, for unit
  testing hook modules without a LiveView.
  """

  @doc "Runs each module's `on_mount(:default, ...)` in order."
  def mounted_socket(modules) do
    socket = %Phoenix.LiveView.Socket{
      assigns: %{__changed__: %{}},
      private: %{lifecycle: %Phoenix.LiveView.Lifecycle{}, live_temp: %{}}
    }

    Enum.reduce(modules, socket, fn module, socket ->
      {:cont, socket} = module.on_mount(:default, %{}, %{}, socket)
      socket
    end)
  end
end
