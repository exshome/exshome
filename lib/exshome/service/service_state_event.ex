defmodule Exshome.Service.ServiceStateEvent do
  @moduledoc """
  Event related to service state.
  """

  defstruct [:id, :pid, :state]

  @type t() :: %__MODULE__{
          id: Exshome.Id.t(),
          pid: pid(),
          state: :started | :stopped
        }

  use Exshome.Behaviours.EmitterBehaviour, type: Exshome.Event
end
