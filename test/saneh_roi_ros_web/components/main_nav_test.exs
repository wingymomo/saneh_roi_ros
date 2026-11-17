defmodule SanehRoiRosWeb.MainNavTest do
  use SanehRoiRosUI.ComponentCase, async: true

  import SanehRoiRosWeb.LiveSocketHelpers

  alias SanehRoiRosWeb.{MainNav, Toast}

  doctest SanehRoiRosWeb.MainNav

  describe "main_nav/1" do
    test "staff: only orders is a link; the rest are grey and send main_nav_denied" do
      doc = render(&MainNav.main_nav/1, role: :staff, current: :orders)

      assert attr(doc, "#bottom-nav-orders", "href") == "/"
      assert attr(doc, "#bottom-nav-orders", "aria-current") == "page"

      for item <- ~w(menu sales accounts settings) do
        sel = "#bottom-nav-#{item}"
        assert attr(doc, sel, "aria-disabled") == "true"
        assert attr(doc, sel, "phx-click") == "main_nav_denied"
        assert attr(doc, sel, "phx-value-item") == item
      end
    end

    test "manager can open the menu page; owner can open everything" do
      manager = render(&MainNav.main_nav/1, role: :manager)
      owner = render(&MainNav.main_nav/1, role: :owner, paths: %{sales: "/reports"})

      assert attr(manager, "#bottom-nav-menu", "href") == "/menu"
      assert attr(manager, "#bottom-nav-sales", "aria-disabled") == "true"
      refute has?(owner, "[aria-disabled]")
      assert attr(owner, "#bottom-nav-sales", "href") == "/reports"
    end
  end

  test "items/2 marks what a role may not open" do
    disabled = for i <- MainNav.items(:manager), i.disabled, do: i.key
    assert disabled == [:sales, :accounts, :settings]
  end

  test "allowed?/2 follows the permission table" do
    assert MainNav.allowed?(:staff, :orders)
    refute MainNav.allowed?(:staff, :menu)
    assert MainNav.allowed?(:manager, :menu)
    refute MainNav.allowed?(:manager, :settings)
    assert MainNav.allowed?(:owner, "accounts")
    refute MainNav.allowed?(:owner, "unknown")
  end

  test "the hook turns a denied tap into a toast; other events pass on" do
    s = mounted_socket([Toast, MainNav])

    assert {:halt, s} = MainNav.handle_event("main_nav_denied", %{"item" => "settings"}, s)
    assert s.assigns.toast.message == "ตั้งค่า เปิดได้เฉพาะเจ้าของร้าน"
    assert s.assigns.toast.action == nil

    assert {:cont, ^s} = MainNav.handle_event("other", %{}, s)
  end

  test "requires Toast to be mounted" do
    assert_raise ArgumentError, fn -> mounted_socket([MainNav]) end
  end
end
