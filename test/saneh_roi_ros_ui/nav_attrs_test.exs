defmodule SanehRoiRosUI.NavAttrsTest do
  use ExUnit.Case, async: true

  alias SanehRoiRosUI.NavAttrs

  test "link only with a target and not disabled" do
    assert NavAttrs.link?(%{navigate: "/a"})
    assert NavAttrs.link?(%{href: "/a", disabled: false})
    refute NavAttrs.link?(%{navigate: "/a", disabled: true})
    refute NavAttrs.link?(%{navigate: "/a", disabled: ""})
    refute NavAttrs.link?(%{"phx-click": "x"})
  end

  test "split/1 drops navigation attrs when it is not a link" do
    assert {true, %{patch: "/p"}} = NavAttrs.split(%{patch: "/p"})

    assert {false, rest} =
             NavAttrs.split(%{navigate: "/a", replace: true, disabled: true, id: "x"})

    assert rest == %{disabled: true, id: "x"}
  end
end
