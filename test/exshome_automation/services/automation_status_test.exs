defmodule ExshomeAutomationTest.Services.AutomationStatusTest do
  use Exshome.DataCase, async: true

  alias Exshome.Dependency
  alias ExshomeAutomation.Services.AutomationStatus
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomePlayer.Variables.Pause
  alias ExshomeTest.TestRegistry

  setup do
    Dependency.subscribe(AutomationStatus)
    TestRegistry.start_dependency(VariableRegistry)
    TestRegistry.start_dependency(AutomationStatus)
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

  defp start_variable do
    flush_messages()
    TestRegistry.start_dependency(Pause)
    assert_receive_dependency({AutomationStatus, _})
  end

  defp stop_variable do
    flush_messages()
    TestRegistry.stop_dependency(Pause)
    assert_receive_dependency({AutomationStatus, _})
  end

  defp count_variables do
    assert %AutomationStatus{variables: variables} = Dependency.get_value(AutomationStatus)
    variables
  end
end
