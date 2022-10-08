defmodule ExshomeAutomationTest.Services.Workflow.WorkflowSupervisorTest do
  use ExshomeTest.DataCase, async: true

  alias ExshomeAutomation.Services.Workflow.Schema
  import ExshomeTest.WorkflowHelpers

  test "no workflows" do
    start_workflow_supervisor()
  end

  test "starts multiple workflows" do
    amount = Enum.random(1..5)

    for _ <- 1..amount do
      %Schema{} = Schema.create!()
    end

    pid = start_workflow_supervisor()
    assert %{active: ^amount, workers: ^amount} = Supervisor.count_children(pid)
    Supervisor.stop(pid)
  end
end
