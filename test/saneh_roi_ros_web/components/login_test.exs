defmodule SanehRoiRosWeb.LoginTest do
  use SanehRoiRosUI.ComponentCase, async: true

  import SanehRoiRosWeb.Login

  alias SanehRoiRosWeb.Login

  describe "login" do
    test "name_tile shows initial, name and role; selected is pressed" do
      doc = render(&Login.name_tile/1, id: "n", name: "นิด", role: :staff, selected: true)

      assert attr(doc, "#n", "aria-pressed") == "true"
      assert text(doc, "#n b") == "นิด"
      assert text(doc, "#n small") == "พนักงาน"
      assert "bg-primary" in classes(doc, "#n")

      accent = render(&Login.name_tile/1, id: "m", name: "เมย์", role: :manager)

      assert attr(accent, "#m", "aria-pressed") == "false"
      assert "text-brown" in classes(accent, "#m small")
      assert text(accent, "#m small") == "ผู้จัดการ"
    end

    test "pin_dots fills the first N dots" do
      doc = render(&Login.pin_dots/1, id: "p", filled: 2)

      assert doc |> q("#p span[data-filled]") |> Enum.count() == 2
      assert doc |> q("#p span") |> Enum.count() == 4
      assert attr(doc, "#p", "aria-label") == "ใส่รหัสแล้ว 2 จาก 4 หลัก"
    end

    test "keypad has digits 0-9, backspace and an optional extra key" do
      assigns = %{}

      doc =
        parse(~H"""
        <.keypad id="k" on_digit="digit" on_backspace="back" on_extra="random">
          <:extra>สุ่มให้</:extra>
        </.keypad>
        """)

      for d <- 0..9 do
        assert attr(doc, "#k-#{d}", "phx-click") == "digit"
        assert attr(doc, "#k-#{d}", "phx-value-digit") == "#{d}"
      end

      assert attr(doc, "#k-backspace", "phx-click") == "back"
      assert attr(doc, "#k-extra", "phx-click") == "random"
      assert text(doc, "#k-extra") == "สุ่มให้"

      plain = render(&Login.keypad/1, id: "k2")
      refute has?(plain, "#k2-extra")
      assert plain |> q("#k2 > *") |> Enum.count() == 12
    end
  end
end
