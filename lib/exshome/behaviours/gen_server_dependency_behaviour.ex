defmodule Exshome.Behaviours.GenServerDependencyBehaviour do
  @moduledoc """
  Behaviour for GenServerDependency.
  """

  alias Exshome.Dependency.GenServerDependency.DependencyState

  @callback on_init(DependencyState.t()) :: DependencyState.t()
  @callback update_data(DependencyState.t(), update_fn :: (any() -> any())) :: DependencyState.t()
  @callback update_value(DependencyState.t(), update_fn :: (any() -> any())) ::
              DependencyState.t()
  @callback handle_info(message :: any(), DependencyState.t()) ::
              {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason :: term(), new_state}
            when new_state: DependencyState.t()
  @callback handle_call(request :: term(), GenServer.from(), state :: DependencyState.t()) ::
              {:reply, reply, new_state}
              | {:reply, reply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:noreply, new_state}
              | {:noreply, new_state, timeout() | :hibernate | {:continue, term()}}
              | {:stop, reason, reply, new_state}
              | {:stop, reason, new_state}
            when reply: term(), new_state: DependencyState.t(), reason: term()
  @callback handle_stop(reason :: term(), state :: DependencyState.t()) :: DependencyState.t()
  @optional_callbacks handle_info: 2, handle_call: 3
end
