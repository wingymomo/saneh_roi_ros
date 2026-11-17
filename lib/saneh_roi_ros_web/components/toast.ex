defmodule SanehRoiRosWeb.Toast do
  @moduledoc """
  The page's single toast, shared by every feature that wants to show one
  (quick add, main nav, …).

  Mount it once per LiveView, render `app_toast/1` once, and call `put/3`:

      on_mount SanehRoiRosWeb.Toast

      <.app_toast toast={@toast} />

      socket |> SanehRoiRosWeb.Toast.put("บันทึกแล้ว")

  It keeps `@toast` (`nil` when none) and handles `"toast_dismiss"`, which the
  UI kit's toast pushes once it has hidden itself.
  """
  use Phoenix.Component

  import Phoenix.LiveView, only: [attach_hook: 4]

  @dismiss_event "toast_dismiss"

  @doc false
  def on_mount(:default, _params, _session, socket) do
    {:cont,
     socket
     |> assign(:toast, nil)
     |> attach_hook(:toast, :handle_event, &handle_event/3)}
  end

  @doc false
  def handle_event(@dismiss_event, %{"key" => key}, socket), do: {:halt, dismiss(socket, key)}
  def handle_event(_event, _params, socket), do: {:cont, socket}

  @doc """
  Shows `message`, replacing any current toast.

  Options:

    * `:action` — action button label, e.g. "ยกเลิก"
    * `:on_action` — event sent by the action button
    * `:meta` — any term the action handler needs (read it back from `@toast.meta`)
  """
  def put(socket, message, opts \\ []) do
    toast = %{
      key: Integer.to_string(System.unique_integer([:positive])),
      message: message,
      action: opts[:action],
      on_action: opts[:on_action],
      meta: opts[:meta]
    }

    assign(socket, :toast, toast)
  end

  @doc "Hides the toast."
  def clear(socket), do: assign(socket, :toast, nil)

  @doc """
  Clears the toast once the browser has hidden it. Ignored when a newer toast
  (another `key`) has replaced it meanwhile.
  """
  def dismiss(socket, key) do
    case socket.assigns.toast do
      %{key: ^key} -> clear(socket)
      _ -> socket
    end
  end

  @doc false
  def ensure_mounted!(socket, by) do
    unless Map.has_key?(socket.assigns, :toast) do
      raise ArgumentError,
            "#{inspect(by)} shows toasts: put `on_mount SanehRoiRosWeb.Toast` before `on_mount #{inspect(by)}`"
    end

    socket
  end

  @doc "Renders `@toast` with the UI kit's toast."
  attr :toast, :map, default: nil
  attr :id, :string, default: "toast"
  attr :duration, :integer, default: 4000
  attr :position, :atom, default: :fixed

  def app_toast(assigns) do
    ~H"""
    <SanehRoiRosUI.toast
      :if={@toast}
      id={@id}
      key={@toast.key}
      duration={@duration}
      position={@position}
      action={@toast.action}
      on_action={@toast.on_action}
      on_dismiss="toast_dismiss"
    >
      {@toast.message}
    </SanehRoiRosUI.toast>
    """
  end
end
