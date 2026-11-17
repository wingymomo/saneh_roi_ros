defmodule SanehRoiRosWeb.ToastTest do
  use SanehRoiRosUI.ComponentCase, async: true

  import SanehRoiRosWeb.LiveSocketHelpers

  alias SanehRoiRosWeb.Toast

  test "on_mount starts with no toast" do
    assert mounted_socket([Toast]).assigns.toast == nil
  end

  test "put/3 shows a message with a fresh key, and optional action and meta" do
    s = mounted_socket([Toast]) |> Toast.put("บันทึกแล้ว")

    assert %{message: "บันทึกแล้ว", action: nil, on_action: nil, meta: nil, key: k1} =
             s.assigns.toast

    s = Toast.put(s, "เพิ่ม โค้ก แล้ว", action: "ยกเลิก", on_action: "undo", meta: {:x, 1})
    assert %{action: "ยกเลิก", on_action: "undo", meta: {:x, 1}, key: k2} = s.assigns.toast
    assert k1 != k2
  end

  test "dismiss/2 clears only the toast with the matching key" do
    s = mounted_socket([Toast]) |> Toast.put("hi")
    key = s.assigns.toast.key

    assert Toast.dismiss(s, "stale").assigns.toast
    refute Toast.dismiss(s, key).assigns.toast
  end

  test "the hook handles toast_dismiss and passes other events on" do
    s = mounted_socket([Toast]) |> Toast.put("hi")

    assert {:halt, s2} = Toast.handle_event("toast_dismiss", %{"key" => s.assigns.toast.key}, s)
    assert s2.assigns.toast == nil
    assert {:cont, ^s} = Toast.handle_event("other", %{}, s)
  end

  test "features that show toasts require Toast to be mounted first" do
    assert_raise ArgumentError, ~r/on_mount SanehRoiRosWeb.Toast/, fn ->
      mounted_socket([SanehRoiRosWeb.QuickAdd])
    end
  end

  describe "app_toast/1" do
    test "renders nothing without a toast" do
      refute has?(render(&Toast.app_toast/1, toast: nil), "#toast")
    end

    test "renders message, action and the dismiss event" do
      toast = %{key: "k1", message: "เพิ่ม โค้ก แล้ว", action: "ยกเลิก", on_action: "undo", meta: nil}
      doc = render(&Toast.app_toast/1, toast: toast, duration: 2000)

      assert text(doc, "#toast span") == "เพิ่ม โค้ก แล้ว"
      assert attr(doc, "#toast", "data-key") == "k1"
      assert attr(doc, "#toast", "data-duration") == "2000"
      assert attr(doc, "#toast", "data-on-dismiss") == "toast_dismiss"
      assert attr(doc, "#toast-action", "phx-click") == "undo"
    end

    test "no action button without an action" do
      toast = %{key: "k2", message: "hi", action: nil, on_action: nil, meta: nil}
      refute has?(render(&Toast.app_toast/1, toast: toast), "#toast-action")
    end
  end
end
