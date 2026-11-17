defmodule SanehRoiRosWeb.TableTileTest do
  use SanehRoiRosUI.ComponentCase, async: true

  import SanehRoiRosWeb.TableTile

  alias SanehRoiRosWeb.TableTile

  describe "table_tile/1" do
    test "free table" do
      doc = render(&TableTile.table_tile/1, id: "t2", number: 2)

      assert attr(doc, "#t2", "data-busy") == nil
      assert attr(doc, "#t2", "aria-label") == "โต๊ะ 2 ว่าง"
      assert text(doc, "#t2") =~ "ว่าง"
      refute has?(doc, "#t2 [data-role=queues]")
    end

    test "busy table lists the queue number of every round" do
      doc =
        render(&TableTile.table_tile/1, id: "t1", number: 1, queues: [3, 7], "phx-click": "open")

      assert attr(doc, "#t1", "data-busy") == ""
      assert "bg-wait" in classes(doc, "#t1")
      assert text(doc, "#t1 [data-role=queues]") == "#3 #7"
      assert text(doc, "#t1") =~ "มีลูกค้า"
      assert attr(doc, "#t1", "phx-click") == "open"
    end

    test "grid has 3 columns" do
      assigns = %{}
      doc = parse(~H|<.table_grid id="g"><.table_tile number={1} /></.table_grid>|)
      assert "grid-cols-3" in classes(doc, "#g")
    end
  end

  test "a disabled tile with navigate is a disabled button (e.g. busy table when moving)" do
    doc =
      render(&TableTile.table_tile/1,
        id: "t1",
        number: 1,
        queues: [3],
        navigate: "/t/1",
        disabled: true
      )

    assert has?(doc, "button#t1[disabled]")
    refute has?(doc, "a")
  end
end
