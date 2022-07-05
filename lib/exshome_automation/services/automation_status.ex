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

  defstruct [:variables]

  @type t() :: %__MODULE__{
          variables: integer()
        }

  @impl Subscription
  def handle_dependency_change(%DependencyState{} = state) do
    update_value(
      state,
      %__MODULE__{
        variables: state.deps.variables |> Enum.count()
      }
    )
  end
end
