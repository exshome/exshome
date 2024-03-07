defmodule Exshome.Variable.VariableConfig do
  @moduledoc """
  Stores informatin about the state of variable.
  """

  defstruct [
    :dependency,
    :id,
    :name,
    :group,
    :not_ready_reason,
    :readonly?,
    :can_delete?,
    :can_rename?,
    :type,
    :validations
  ]

  @type t() :: %__MODULE__{
          dependency: Exshome.Emitter.id(),
          id: String.t(),
          name: String.t(),
          group: String.t(),
          not_ready_reason: String.t() | nil,
          readonly?: boolean(),
          can_delete?: boolean(),
          can_rename?: boolean(),
          type: Exshome.Datatype.t(),
          validations: %{atom() => any()}
        }
end
