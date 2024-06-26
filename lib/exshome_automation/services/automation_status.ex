defmodule ExshomeAutomation.Services.AutomationStatus do
  @moduledoc """
  Stores information about automation status.
  """
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Services.WorkflowRegistry

  use Exshome.Service.DependencyService,
    app: ExshomeAutomation,
    name: "automation_status",
    dependencies: [
      variables: VariableRegistry,
      workflows: WorkflowRegistry
    ]

  defstruct [
    :ready_variables,
    :not_ready_variables,
    :ready_workflows,
    :not_ready_workflows
  ]

  @type t() :: %__MODULE__{
          ready_variables: integer(),
          not_ready_variables: integer(),
          ready_workflows: integer(),
          not_ready_workflows: integer()
        }

  @impl DependencyServiceBehaviour
  def handle_dependency_change(%ServiceState{deps: deps} = state) do
    {ready_variables, not_ready_variables} =
      deps.variables
      |> Map.values()
      |> Enum.split_with(&(!&1.not_ready_reason))

    {ready_workflows, not_ready_workflows} =
      deps.workflows
      |> Map.values()
      |> Enum.split_with(& &1.active)

    update_value(
      state,
      fn _ ->
        %__MODULE__{
          ready_variables: Enum.count(ready_variables),
          not_ready_variables: Enum.count(not_ready_variables),
          ready_workflows: Enum.count(ready_workflows),
          not_ready_workflows: Enum.count(not_ready_workflows)
        }
      end
    )
  end
end
