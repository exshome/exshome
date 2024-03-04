defmodule ExshomeTest.NamedTest do
  use ExUnit.Case, async: true
  alias Exshome.Named
  alias ExshomeClock.Settings.ClockSettings
  import ExshomeTest.MacroHelpers, only: [compile_with_settings: 2]

  describe "get_module_by_name/1" do
    test "works fine" do
      assert Named.get_module_by_name(ClockSettings.get_name()) == {:ok, ClockSettings}
    end

    test "fails for unknown module" do
      assert Named.get_module_by_name("unknown module") == {:error, :not_found}
    end
  end

  describe "__using__/1" do
    test "works fine" do
      compile_with_settings(Named, "valid_name")
    end
  end
end
