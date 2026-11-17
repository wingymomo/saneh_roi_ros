defmodule SanehRoiRosWeb.QuickAddTest do
  use SanehRoiRosUI.ComponentCase, async: true

  import SanehRoiRosWeb.LiveSocketHelpers

  alias SanehRoiRosWeb.{QuickAdd, Toast}

  defp socket, do: mounted_socket([Toast, QuickAdd])

  test "on_mount starts with no counts" do
    assert socket().assigns.quick_add_counts == %{}
  end

  describe "add/3" do
    test "counts up on every tap and shows an undo toast with the running total" do
      s = socket() |> QuickAdd.add("coke-can", "โค้ก กระป๋อง")
      assert s.assigns.quick_add_counts == %{"coke-can" => 1}

      assert %{
               message: "เพิ่ม โค้ก กระป๋อง แล้ว (รวม 1)",
               action: "ยกเลิก",
               on_action: "quick_add_undo"
             } = s.assigns.toast

      s = QuickAdd.add(s, "coke-can", "โค้ก กระป๋อง")
      assert s.assigns.quick_add_counts == %{"coke-can" => 2}
      assert s.assigns.toast.message == "เพิ่ม โค้ก กระป๋อง แล้ว (รวม 2)"
    end
  end

  describe "undo/1" do
    test "takes back the last tap and hides the toast" do
      s =
        socket()
        |> QuickAdd.add("coke-can", "โค้ก")
        |> QuickAdd.add("coke-can", "โค้ก")
        |> QuickAdd.undo()

      assert s.assigns.quick_add_counts == %{"coke-can" => 1}
      assert s.assigns.toast == nil
    end

    test "removes the item when its count drops to zero" do
      s = socket() |> QuickAdd.add("water", "น้ำเปล่า") |> QuickAdd.undo()
      assert s.assigns.quick_add_counts == %{}
    end

    test "leaves another feature's toast alone" do
      s =
        socket()
        |> QuickAdd.put_counts(%{"coke-can" => 2})
        |> Toast.put("ยอดขาย เปิดได้เฉพาะเจ้าของร้าน")
        |> QuickAdd.undo()

      assert s.assigns.quick_add_counts == %{"coke-can" => 2}
      assert s.assigns.toast.message == "ยอดขาย เปิดได้เฉพาะเจ้าของร้าน"
    end
  end

  describe "handle_event/3 hook" do
    test "handles its own events and halts" do
      s = socket()

      assert {:halt, s} = QuickAdd.handle_event("quick_add", %{"sku" => "a", "label" => "A"}, s)
      assert s.assigns.quick_add_counts == %{"a" => 1}

      assert {:halt, s} = QuickAdd.handle_event("quick_add_undo", %{}, s)
      assert s.assigns.quick_add_counts == %{}
    end

    test "passes other events on to the LiveView" do
      s = socket()
      assert {:cont, ^s} = QuickAdd.handle_event("toast_dismiss", %{}, s)
    end
  end

  test "count/2 and total_count/1" do
    counts = %{"a" => 2, "b" => 3}
    assert QuickAdd.count(counts, "a") == 2
    assert QuickAdd.count(counts, "zzz") == 0
    assert QuickAdd.total_count(counts) == 5
  end

  test "quick_add_button/1 wraps the tally button with the add event and current count" do
    doc =
      render(&QuickAdd.quick_add_button/1,
        sku: "coke-can",
        label: "โค้ก กระป๋อง",
        price: 16,
        counts: %{"coke-can" => 2}
      )

    assert attr(doc, "#quick-add-coke-can", "phx-click") == "quick_add"
    assert attr(doc, "#quick-add-coke-can", "phx-value-sku") == "coke-can"
    assert attr(doc, "#quick-add-coke-can", "phx-value-label") == "โค้ก กระป๋อง"
    assert attr(doc, "#quick-add-coke-can", "aria-label") == "โค้ก กระป๋อง 16 บาท"
    assert text(doc, "#quick-add-coke-can-count") == "2"
  end
end
