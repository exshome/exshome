defmodule ExshomeAutomationTest.Services.AutomationStatusTest do
  use ExshomeTest.DataCase, async: true

  alias Exshome.Dependency
  alias Exshome.Emitter
  alias ExshomeAutomation.Services.AutomationStatus
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Services.WorkflowRegistry
  alias ExshomePlayer.Services.PlayerState
  alias ExshomePlayer.Variables.Volume
  alias ExshomeTest.TestRegistry

  setup do
    Emitter.subscribe(AutomationStatus)
    TestRegistry.start_service(VariableRegistry)
    TestRegistry.start_service(WorkflowRegistry)
    TestRegistry.start_service(AutomationStatus)
  end

  test "shows empty data" do
    assert %AutomationStatus{
             ready_variables: 0,
             not_ready_variables: 0,
             ready_workflows: 0,
             not_ready_workflows: 0
           } = Dependency.get_value(AutomationStatus)
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
    TestRegistry.start_service(Volume)
    assert_receive_dependency({AutomationStatus, _})
  end

  defp make_variable_ready do
    assert :ok = Emitter.broadcast(PlayerState, %PlayerState{})
    assert_receive_dependency({AutomationStatus, _})
  end

  defp stop_variable do
    flush_messages()
    TestRegistry.stop_service(Volume)
    assert_receive_dependency({AutomationStatus, _})
  end
end
