defmodule ExshomeAutomation.Variables.DynamicVariable.VariableSupervisor do
  @moduledoc """
  Supervisor that starts all dynamic variables.
  """

  alias ExshomeAutomation.Variables.DynamicVariable
  alias ExshomeAutomation.Variables.DynamicVariable.Schema
  use Exshome.Dependency.DynamicDependencySupervisor

  @impl DynamicDependencySupervisor
  defdelegate list(), to: Schema

  @impl DynamicDependencySupervisor
  def child_module, do: DynamicVariable
end
