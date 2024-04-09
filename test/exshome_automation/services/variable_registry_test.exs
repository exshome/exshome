defmodule ExshomeAutomationTest.Services.VariableRegistryTest do
  use ExshomeTest.DataCase, async: true

  alias Exshome.Dependency
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomePlayer.Variables.Pause
  alias ExshomeTest.TestRegistry

  describe "without started variables" do
    setup do
      TestRegistry.start_service(VariableRegistry)
    end

    test "shows empty data" do
      assert count_variables() == 0
    end

    test "start variable" do
      start_variable()
      assert count_variables() == 1
    end

    test "stop variable" do
      start_variable()
      assert count_variables() == 1
      stop_variable()
      assert count_variables() == 0
    end
  end

  defp start_variable do
    TestRegistry.start_service(Pause)
  end

  defp stop_variable do
    TestRegistry.stop_service(Pause)
  end

  defp count_variables do
    VariableRegistry
    |> Dependency.get_value()
    |> Map.keys()
    |> length()
  end
end
