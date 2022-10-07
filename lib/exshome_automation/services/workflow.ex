defmodule ExshomeAutomation.Services.Workflow do
  @moduledoc """
  A module for automation workflows.
  """

  alias Exshome.SystemRegistry
  alias ExshomeAutomation.Services.Workflow.Schema
  alias ExshomeAutomation.Services.Workflow.WorkflowSupervisor

  defstruct [:active, :id, :name]

  @type t() :: %__MODULE__{
          active: boolean(),
          id: String.t(),
          name: String.t()
        }

  use Exshome.Dependency.GenServerDependency,
    name: "automation_workflow",
    child_module: WorkflowSupervisor

  @impl GenServerDependency
  def on_init(%DependencyState{} = state) do
    {__MODULE__, id} = state.dependency
    %Schema{name: name} = Schema.get!(id)

    value = %__MODULE__{
      active: true,
      id: id,
      name: name
    }

    SystemRegistry.register!(__MODULE__, id, value)

    update_value(state, fn _ -> value end)
  end

  @spec list() :: [t()]
  def list, do: SystemRegistry.list(__MODULE__)
end
