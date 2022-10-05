defmodule ExshomeTest.DynamicVariableHelpers do
  @moduledoc """
  Helper functions for testing dynamic variables.
  """

  import ExshomeTest.Fixtures
  alias Exshome.Dependency
  alias Exshome.Repo
  alias ExshomeAutomation.Variables.DynamicVariable
  alias ExshomeAutomation.Variables.DynamicVariable.Schema
  alias ExshomeAutomation.Variables.DynamicVariable.VariableSupervisor
  alias ExshomeTest.Hooks.DynamicDependencySupervisor
  alias ExshomeTest.TestRegistry

  @spec start_dynamic_variable_supervisor() :: pid()
  def start_dynamic_variable_supervisor do
    pid =
      %{}
      |> TestRegistry.prepare_child_opts()
      |> Map.put(:supervisor_opts, name: nil)
      |> VariableSupervisor.child_spec()
      |> ExUnit.Callbacks.start_supervised!()

    :ok = DynamicDependencySupervisor.put_supervisor_pid(VariableSupervisor, pid)
    pid
  end

  @spec get_dynamic_variable_value(String.t()) :: Dependency.value()
  def get_dynamic_variable_value(id) when is_binary(id) do
    Dependency.get_value({DynamicVariable, id})
  end

  @spec create_dynamic_variable_with_unknown_type() :: Schema.t()
  def create_dynamic_variable_with_unknown_type do
    {:ok, schema} =
      Repo.insert(%Schema{
        type: "unknown_datatype#{unique_integer()}"
      })

    schema
  end
end
