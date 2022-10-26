defmodule ExshomeAutomation.Services.Workflow.Editor do
  @moduledoc """
  Editor logic for workflow.
  """

  defstruct [:id, :x, :y]

  @type t() :: %__MODULE__{
          id: String.t(),
          x: number(),
          y: number()
        }

  @spec blank_editor() :: [t()]
  def blank_editor, do: []
end
