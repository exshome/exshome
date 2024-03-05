defmodule ExshomeAutomation.Services.AutomationStatus do
  @moduledoc """
  Stores information about automation status.
  """
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Services.WorkflowRegistry

  use Exshome.Dependency.GenServerDependency,
    app: ExshomeAutomation,
    name: "automation_status",
    subscribe: [
      dependencies: [
        {VariableRegistry, :variables},
        {WorkflowRegistry, :workflows}
      ]
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

  @impl Subscription
  def on_dependency_change(%DependencyState{} = state) do
    {ready_variables, not_ready_variables} =
      state.deps.variables
      |> Map.values()
      |> Enum.split_with(&(!&1.not_ready_reason))

    {ready_workflows, not_ready_workflows} =
      state.deps.workflows
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
