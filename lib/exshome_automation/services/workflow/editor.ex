defmodule ExshomeAutomation.Services.Workflow.Editor do
  @moduledoc """
  Editor logic for workflow.
  """

  defstruct [
    :id,
    :x,
    :y,
    :type
  ]

  @type t() :: %__MODULE__{
          id: String.t(),
          x: number(),
          y: number(),
          type: String.t()
        }

  @spec blank_editor() :: [t()]
  def blank_editor, do: []

  @spec add_item([t()], t()) :: [t()]
  def add_item(state, %__MODULE__{} = item) do
    [item | state]
  end

  @spec create_default_item(type :: String.t()) :: t()
  def create_default_item(type) when is_binary(type) do
    %__MODULE__{
      id: Ecto.UUID.autogenerate(),
      x: 0,
      y: 0,
      type: type
    }
  end
end
