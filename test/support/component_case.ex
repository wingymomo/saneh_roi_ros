defmodule SanehRoiRosUI.ComponentCase do
  @moduledoc """
  Helpers for rendering `SanehRoiRosUI` function components in unit tests and
  asserting on the resulting DOM with `LazyHTML`.
  """
  use ExUnit.CaseTemplate

  require Phoenix.LiveViewTest

  using do
    quote do
      import Phoenix.Component, only: [sigil_H: 2]
      import Phoenix.LiveViewTest, only: [rendered_to_string: 1]
      import SanehRoiRosUI.ComponentCase

      alias SanehRoiRosUI, as: UI
    end
  end

  @doc "Renders a component function with `assigns` and parses the HTML."
  def render(fun, assigns \\ %{}) do
    fun
    |> Phoenix.LiveViewTest.render_component(assigns)
    |> LazyHTML.from_fragment()
  end

  @doc "Builds a static slot for `render/2`, e.g. `inner_block: slot(\"text\")`."
  def slot(text) do
    [%{__slot__: :inner_block, inner_block: fn _, _ -> text end}]
  end

  @doc "Parses an already-rendered `~H` template."
  def parse(rendered),
    do: rendered |> Phoenix.LiveViewTest.rendered_to_string() |> LazyHTML.from_fragment()

  @doc "Elements matching `selector`."
  def q(doc, selector), do: LazyHTML.query(doc, selector)

  @doc "Whether `selector` matches at least one element."
  def has?(doc, selector), do: Enum.count(q(doc, selector)) > 0

  @doc "Value of `name` on the first element matching `selector` (nil when absent)."
  def attr(doc, selector, name) do
    doc |> q(selector) |> LazyHTML.attribute(name) |> List.first()
  end

  @doc "Whitespace-normalised text of the elements matching `selector`."
  def text(doc, selector) do
    doc |> q(selector) |> LazyHTML.text() |> String.split() |> Enum.join(" ")
  end

  @doc "Class list of the first element matching `selector`."
  def classes(doc, selector) do
    (attr(doc, selector, "class") || "") |> String.split()
  end
end
