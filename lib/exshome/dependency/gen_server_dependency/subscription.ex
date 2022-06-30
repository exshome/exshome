defmodule Exshome.Dependency.GenServerDependency.Subscription do
  @moduledoc """
  Subsription workflow for GenServerDependency.
  """
  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  alias Exshome.Event

  use Lifecycle, key: :subscribe

  @callback update_data(DependencyState.t(), (any() -> any())) :: DependencyState.t()
  @callback update_value(DependencyState.t(), value :: any()) :: DependencyState.t()
  @callback handle_dependency_change(DependencyState.t()) :: DependencyState.t()
  @callback handle_event(Event.event_message(), DependencyState.t()) :: DependencyState.t()

  @impl Lifecycle
  def on_init(%DependencyState{module: module} = state) do
    dependencies = get_config(module)[:dependencies] || []
    events = get_config(module)[:events] || []

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
      state.module
      |> get_config()
      |> Keyword.fetch!(:dependencies)
      |> Keyword.fetch!(dependency)

    put_in(state.deps[key], value)
    |> handle_dependency_change()
  end

  def validate_module!(%Macro.Env{module: module}, _) do
    module
    |> get_config()
    |> NimbleOptions.validate!(
      dependencies: [
        type: :keyword_list,
        keys: [
          *: [
            type: :atom
          ]
        ]
      ],
      events: [
        type: {:list, :atom}
      ]
    )
  end

  defmacro __using__(_opts) do
    quote do
      alias Exshome.Dependency.GenServerDependency.Subscription
      import Exshome.Dependency.GenServerDependency.Lifecycle, only: [register_hook_module: 1]
      register_hook_module(Subscription)

      @after_compile {Subscription, :validate_module!}
      @behaviour Subscription

      @impl Subscription
      defdelegate update_value(state, value), to: Subscription
      @impl Subscription
      defdelegate update_data(state, data_fn), to: Subscription

      @impl Subscription
      def handle_dependency_change(state) do
        Logger.warn("""
        Some module dependency changed.
        Please implement handle_dependency_change/1 callback for #{state.module}
        """)

        state
      end

      @impl Subscription
      def handle_event(event, %DependencyState{} = state) do
        Logger.warn("""
        Received unexpected event #{inspect(event)},
        Please implement handle_event/2 callback for #{state.module}
        """)

        state
      end

      defoverridable(handle_dependency_change: 1, handle_event: 2)
    end
  end
end
