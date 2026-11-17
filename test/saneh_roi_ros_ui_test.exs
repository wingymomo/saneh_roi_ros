defmodule SanehRoiRosUITest do
  use ExUnit.Case, async: true

  doctest SanehRoiRosUI

  describe "baht/1" do
    test "formats whole baht with thousands separators and no ฿" do
      assert SanehRoiRosUI.baht(0) == "0 บาท"
      assert SanehRoiRosUI.baht(60) == "60 บาท"
      assert SanehRoiRosUI.baht(1_250) == "1,250 บาท"
      assert SanehRoiRosUI.baht(1_234_567) == "1,234,567 บาท"
      assert SanehRoiRosUI.baht(-130) == "-130 บาท"
    end
  end

  test "the UI kit does not depend on the web layer" do
    for file <- ["lib/saneh_roi_ros_ui.ex" | Path.wildcard("lib/saneh_roi_ros_ui/**/*.ex")] do
      refute File.read!(file) =~ "SanehRoiRosWeb", "#{file} references SanehRoiRosWeb"
    end
  end
end
