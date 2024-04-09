defmodule Exshome.Behaviours.ServiceBehaviour do
  @moduledoc """
  Generic behaviour for each service.
  """
  alias Exshome.Service.ServiceState

  @type settings_t() :: [{module(), Keyword.t()}]

  @callback get_parent_module() :: module()
  @callback start_link(opts :: map()) :: GenServer.on_start()
  @callback service_settings(Exshome.Id.t()) :: settings_t()
  @callback not_ready_value() :: term()
  @callback init(ServiceState.t()) :: ServiceState.t()
  @callback handle_info(message :: term(), ServiceState.t()) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason :: term(), new_state}
            when new_state: ServiceState.t()
  @callback handle_call(request :: term(), GenServer.from(), state :: ServiceState.t()) ::
              {:reply, reply, new_state}
              | {:reply, reply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason, reply, new_state}
              | {:stop, reason, new_state}
            when reply: term(), new_state: ServiceState.t(), reason: term()
  @callback handle_stop(reason :: term(), state :: ServiceState.t()) :: ServiceState.t()
  @optional_callbacks start_link: 1, handle_info: 2, handle_call: 3
end
