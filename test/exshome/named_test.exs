defmodule ExshomeTest.NamedTest do
  use ExUnit.Case, async: true
  alias Exshome.App.Clock.ClockSettings
  alias Exshome.Named
  import ExshomeTest.MacroHelpers, only: [compile_with_settings: 2]

  describe "get_module_by_name/1" do
    test "works fine" do
      assert Named.get_module_by_name(ClockSettings.name()) == ClockSettings
    end

    test "fails for unknown module" do
      assert_raise KeyError, ~r/"unknown module"/, fn ->
        Named.get_module_by_name("unknown module")
      end
    end
  end

  describe "__using__/1" do
    test "works fine" do
      compile_with_settings(Named, "valid_name")
    end
  end
end
