defmodule ExshomeAutomation.Services.Workflow.WorkflowSupervisor do
  @moduledoc """
  Supervisor that starts all automation workflows.
  """

  use Exshome.Dependency.DynamicDependencySupervisor
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Services.Workflow.Schema

  @impl DynamicDependencySupervisor
  defdelegate list(), to: Schema

  @impl DynamicDependencySupervisor
  def child_module, do: Workflow
end
