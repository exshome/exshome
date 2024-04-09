defmodule ExshomeAutomationTest.Services.Workflow.WorkflowSupervisorTest do
  use ExshomeTest.DataCase, async: true

  alias ExshomeAutomation.Services.Workflow.Schema
  alias ExshomeAutomation.Services.Workflow.WorkflowSupervisor
  alias ExshomeTest.TestRegistry

  test "no workflows" do
    TestRegistry.start_dynamic_supervisor(WorkflowSupervisor)
  end

  test "starts multiple workflows" do
    amount = Enum.random(1..5)

    for _ <- 1..amount do
      %Schema{} = Schema.create!()
    end

    pid = TestRegistry.start_dynamic_supervisor(WorkflowSupervisor)
    assert %{active: ^amount, workers: ^amount} = Supervisor.count_children(pid)
    Supervisor.stop(pid)
  end
end
