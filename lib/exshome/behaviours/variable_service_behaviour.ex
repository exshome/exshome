defmodule Exshome.Behaviours.VariableServiceBehaviour do
  @moduledoc """
  Features related to the VariableService.
  """

  alias Exshome.Service.ServiceState
  alias Exshome.Variable.VariableConfig

  @callback not_ready_reason(ServiceState.t()) :: String.t() | nil
  @callback handle_set_value(value :: term(), ServiceState.t()) :: ServiceState.t()
  @callback variable_from_state(ServiceState.t()) :: VariableConfig.t()

  @optional_callbacks handle_set_value: 2
end
