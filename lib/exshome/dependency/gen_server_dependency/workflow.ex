defmodule Exshome.Dependency.GenServerDependency.Workflow do
  @moduledoc """
  Default workflow for GenServerDependency.
  """
  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  alias Exshome.Event

  @behaviour Lifecycle

  @callback update_data(DependencyState.t(), (any() -> any())) :: DependencyState.t()
  @callback update_value(DependencyState.t(), value :: any()) :: DependencyState.t()
  @callback handle_dependency_change(DependencyState.t()) :: DependencyState.t()
  @callback handle_event(Event.event_message(), DependencyState.t()) :: DependencyState.t()

  @impl Lifecycle
  def on_init(%DependencyState{module: module} = state) do
    dependencies = module.__dependency_config__()[:dependencies] || []
    events = module.__dependency_config__()[:events] || []

    state
    |> subscribe_to_dependencies(dependencies)
    |> subscribe_to_events(events)
  end

  @impl Lifecycle
  def handle_call(:get_value, _from, %DependencyState{} = state) do
    {:stop, {state.value, state}}
  end

  @impl Lifecycle
  def handle_call(_message, _from, %DependencyState{} = state), do: {:cont, state}

  @impl Lifecycle
  def handle_info({Dependency, message}, %DependencyState{} = state) do
    {:stop, handle_dependency_info(message, state)}
  end

  @impl Lifecycle
  def handle_info({Event, event}, %DependencyState{} = state) do
    new_state = state.module.handle_event(event, state)
    {:stop, new_state}
  end

  @impl Lifecycle
  def handle_info(_message, %DependencyState{} = state), do: {:cont, state}

  @impl Lifecycle
  def handle_stop(_reason, %DependencyState{module: module} = state) do
    Dependency.broadcast_value(module, Dependency.NotReady)
    {:cont, state}
  end

  @spec subscribe_to_dependencies(DependencyState.t(), Enumerable.t()) :: DependencyState.t()
  def subscribe_to_dependencies(%DependencyState{} = state, dependencies) do
    deps =
      for {dependency, key} <- dependencies, into: %{} do
        {key, Dependency.subscribe(dependency)}
      end

    state = %DependencyState{state | deps: deps}

    if Enum.empty?(deps) do
      state
    else
      handle_dependency_change(state)
    end
  end

  @spec subscribe_to_events(DependencyState.t(), Enumerable.t()) :: DependencyState.t()
  def subscribe_to_events(%DependencyState{} = state, events) do
    for event_module <- events do
      :ok = Event.subscribe(event_module)
    end

    state
  end

  @spec handle_dependency_change(DependencyState.t()) :: DependencyState.t()
  def handle_dependency_change(%DependencyState{deps: deps} = state) do
    missing_dependencies =
      deps
      |> Map.values()
      |> Enum.any?(&(&1 == Dependency.NotReady))

    if missing_dependencies do
      update_value(state, Dependency.NotReady)
    else
      state.module.handle_dependency_change(state)
    end
  end

  @spec update_value(DependencyState.t(), value :: any()) :: DependencyState.t()
  def update_value(%DependencyState{} = state, value) do
    old_value = state.value

    if value != old_value do
      Dependency.broadcast_value(state.module, value)
    end

    %DependencyState{state | value: value}
  end

  @spec update_data(DependencyState.t(), (any() -> any())) :: DependencyState.t()
  def update_data(%DependencyState{} = state, update_fn) do
    %DependencyState{state | data: update_fn.(state.data)}
  end

  @spec handle_dependency_info(any(), DependencyState.t()) :: DependencyState.t()
  def handle_dependency_info({dependency, value}, %DependencyState{} = state) do
    key =
      state.module.__dependency_config__()[:dependencies]
      |> Keyword.fetch!(dependency)

    put_in(state.deps[key], value)
    |> handle_dependency_change()
  end
end
