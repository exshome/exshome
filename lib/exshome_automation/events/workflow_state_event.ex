defmodule ExshomeAutomation.Events.WorkflowStateEvent do
  @moduledoc """
  Event that shows workflow state.
  """

  use Exshome.Event, name: "automation_workflow_state"
  defstruct [:data, :type]

  @type t() :: %__MODULE__{
          data: ExshomeAutomation.Services.Workflow.t(),
          type: :created | :deleted | :updated
        }
end
