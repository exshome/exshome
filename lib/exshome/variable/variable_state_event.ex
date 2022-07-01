defmodule Exshome.Variable.VariableStateEvent do
  @moduledoc """
  Event that shows variable state.
  """

  use Exshome.Event, name: "variable_state"
  defstruct [:data, :type]

  @type t() :: %__MODULE__{
          data: Exshome.Variable.t(),
          type: :created | :deleted
        }
end
