defmodule ExshomeAutomationTest.Services.AutomationStatusTest do
  use Exshome.DataCase, async: true

  alias Exshome.Dependency
  alias ExshomeAutomation.Services.AutomationStatus
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomePlayer.Services.PlayerState
  alias ExshomePlayer.Variables.Volume
  alias ExshomeTest.TestRegistry

  setup do
    Dependency.subscribe(AutomationStatus)
    TestRegistry.start_dependency(VariableRegistry)
    TestRegistry.start_dependency(AutomationStatus)
  end

  test "shows empty data" do
    assert %AutomationStatus{ready_variables: 0, not_ready_variables: 0} =
             Dependency.get_value(AutomationStatus)
  end

  test "start variable" do
    start_variable()

    assert %AutomationStatus{ready_variables: 0, not_ready_variables: 1} =
             Dependency.get_value(AutomationStatus)

    make_variable_ready()

    assert %AutomationStatus{ready_variables: 1, not_ready_variables: 0} =
             Dependency.get_value(AutomationStatus)
  end

  test "stop variable" do
    start_variable()

    assert %AutomationStatus{ready_variables: 0, not_ready_variables: 1} =
             Dependency.get_value(AutomationStatus)

    stop_variable()

    assert %AutomationStatus{ready_variables: 0, not_ready_variables: 0} =
             Dependency.get_value(AutomationStatus)
  end

  defp start_variable do
    flush_messages()
    TestRegistry.start_dependency(Volume)
    assert_receive_dependency({AutomationStatus, _})
  end

  defp make_variable_ready do
    assert :ok = Dependency.broadcast_value(PlayerState, %PlayerState{})
    assert_receive_dependency({AutomationStatus, _})
  end

  defp stop_variable do
    flush_messages()
    TestRegistry.stop_dependency(Volume)
    assert_receive_dependency({AutomationStatus, _})
  end
end
