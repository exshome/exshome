defmodule ExshomeTest.WorkflowHelpers do
  @moduledoc """
  Helper functions for testing workflows.
  """

  alias ExshomeAutomation.Services.Workflow.WorkflowSupervisor
  alias ExshomeTest.Hooks.DynamicDependencySupervisor
  alias ExshomeTest.TestRegistry

  @spec start_workflow_supervisor() :: pid()
  def start_workflow_supervisor do
    pid =
      %{}
      |> TestRegistry.prepare_child_opts()
      |> Map.put(:supervisor_opts, name: nil)
      |> WorkflowSupervisor.child_spec()
      |> ExUnit.Callbacks.start_supervised!()

    :ok = DynamicDependencySupervisor.put_supervisor_pid(WorkflowSupervisor, pid)
    pid
  end
end
