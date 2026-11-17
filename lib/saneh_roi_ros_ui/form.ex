defmodule SanehRoiRosUI.Form do
  @moduledoc """
  Text input / select field: 48px, radius 12, 1.5px border, label 14/600
  above and hint 13 muted below. Focus = 2px primary border on white.

  Works with `Phoenix.HTML.FormField` (`field={@form[:name]}`) or with plain
  `name` / `value`.
  """
  use Phoenix.Component

  import SanehRoiRosUI.Icon

  @doc ~S"""
  Renders a labelled input.

      <UI.input field={@form[:customer]} label="ชื่อลูกค้า (เรียกตอนของเสร็จ)" hint="ไม่บังคับ" />
      <UI.input type="select" field={@form[:role]} label="ตำแหน่ง" options={[{"พนักงาน", "staff"}]} />
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :hint, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(text tel number password search email url select)

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct, e.g. `@form[:name]`"
  attr :errors, :list, default: []
  attr :options, :list, default: [], doc: "options for `type=\"select\"`"
  attr :prompt, :string, default: nil, doc: "prompt for `type=\"select\"`"
  attr :class, :any, default: nil, doc: "extra classes for the wrapper"

  attr :rest, :global,
    include: ~w(autocomplete disabled form inputmode maxlength minlength pattern
                placeholder readonly required step min max phx-debounce)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error/1))
    |> assign_new(:name, fn -> field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(assigns) do
    assigns =
      assigns
      |> assign_new(:name, fn -> nil end)
      |> assign_new(:value, fn -> nil end)
      |> assign(:input_class, [
        "h-12 w-full rounded-md border-[1.5px] bg-surface px-3.5 text-[17px] font-semibold text-primary",
        "outline-none transition-colors duration-150 placeholder:font-normal placeholder:text-icon",
        "focus:border-2 focus:border-primary focus:bg-white focus:px-[13.5px]",
        if(assigns.errors == [], do: "border-line", else: "border-danger")
      ])

    ~H"""
    <div class={["flex flex-col gap-1.5", @class]}>
      <label :if={@label} for={@id} class="text-[14px] font-semibold">{@label}</label>
      <div :if={@type == "select"} class="relative">
        <select
          id={@id}
          name={@name}
          class={[@input_class, "cursor-pointer appearance-none pr-11"]}
          aria-invalid={@errors != [] && "true"}
          {@rest}
        >
          <option :if={@prompt} value="">{@prompt}</option>
          {Phoenix.HTML.Form.options_for_select(@options, @value)}
        </select>
        <.icon
          name="hero-chevron-down"
          class="pointer-events-none absolute top-1/2 right-3.5 size-5 -translate-y-1/2 text-icon"
        />
      </div>
      <input
        :if={@type != "select"}
        type={@type}
        id={@id}
        name={@name}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@input_class}
        aria-invalid={@errors != [] && "true"}
        {@rest}
      />
      <small :if={@hint && @errors == []} class="text-[13px] text-muted">{@hint}</small>
      <small :for={msg <- @errors} class="text-[13px] font-semibold text-danger">{msg}</small>
    </div>
    """
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", fn _ -> to_string(value) end)
    end)
  end

  defp translate_error(msg) when is_binary(msg), do: msg
end
