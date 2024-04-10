defmodule Exshome.Variable.VariableConfig do
  @moduledoc """
  Stores informatin about the state of variable.
  """

  defstruct [
    :service_id,
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
          service_id: Exshome.Id.t(),
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
