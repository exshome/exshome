defmodule Exshome.Behaviours.ServiceExtensionBehaviour do
  @moduledoc """
  Generic service extension operations.
  """
  alias Exshome.Behaviours.ServiceBehaviour
  alias Exshome.Service.ServiceState

  @type default_response() :: {:cont, ServiceState.t()} | {:stop, ServiceState.t()}
  @type call_response() :: {:cont, ServiceState.t()} | {:stop, {term(), ServiceState.t()}}
  @type response() :: default_response() | call_response()

  @doc """
  Validates the extension configuration.
  """
  @callback validate_config!(term()) :: :ok

  @doc """
  Runs after the service has already started, but the module was not inited yet.
  """
  @callback init(ServiceState.t(), ServiceBehaviour.settings_t()) :: ServiceState.t()
  @doc """
  Runs after the service has already started, and the module is already initiated itself.
  """
  @callback after_init(ServiceState.t()) :: ServiceState.t()

  @doc """
  Runs after client sets a new value.
  """
  @callback handle_value_change(old_value :: term(), ServiceState.t()) :: ServiceState.t()

  @callback handle_call(message :: term(), from :: GenServer.from(), state :: ServiceState.t()) ::
              call_response()
  @callback handle_info(message :: term(), state :: ServiceState.t()) :: default_response()
  @callback handle_stop(message :: term(), state :: ServiceState.t()) :: default_response()

  @optional_callbacks [
    after_init: 1,
    handle_call: 3,
    handle_info: 2,
    handle_stop: 2,
    handle_value_change: 2
  ]
end
