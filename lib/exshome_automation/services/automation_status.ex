defmodule ExshomeAutomation.Services.AutomationStatus do
  @moduledoc """
  Stores information about automation status.
  """
  alias ExshomeAutomation.Services.VariableRegistry

  use Exshome.Dependency.GenServerDependency,
    name: "automation_status",
    subscribe: [
      dependencies: [{VariableRegistry, :variables}]
    ]

  defstruct [:ready_variables, :not_ready_variables]

  @type t() :: %__MODULE__{
          ready_variables: integer(),
          not_ready_variables: integer()
        }

  @impl Subscription
  def handle_dependency_change(%DependencyState{} = state) do
    {ready, not_ready} =
      state.deps.variables
      |> Map.values()
      |> Enum.split_with(& &1.ready?)

    update_value(
      state,
      %__MODULE__{
        ready_variables: Enum.count(ready),
        not_ready_variables: Enum.count(not_ready)
      }
    )
  end
end
