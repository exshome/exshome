defmodule Exshome.Dependency.GenServerDependency.Subscription do
  @moduledoc """
  Subsription workflow for GenServerDependency.
  """

  alias Exshome.DataStream
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias Exshome.Event

  use Lifecycle, key: :subscribe

  @callback on_dependency_change(DependencyState.t()) :: DependencyState.t()
  @callback on_event(DependencyState.t(), {Emitter.id(), term()}) :: DependencyState.t()
  @callback on_stream(
              DependencyState.t(),
              {Emitter.id(), Operation.single_operation()}
            ) ::
              DependencyState.t()

  @impl Lifecycle
  def init_state(%DependencyState{dependency: dependency} = state) do
    config =
      dependency
      |> Dependency.get_module()
      |> get_config()

    dependencies = config[:dependencies] || []
    events = config[:events] || []
    streams = config[:streams] || []

    state
    |> put_dependencies(dependencies)
    |> subscribe_to_events(events)
    |> subscribe_to_streams(streams)
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
    new_state = Dependency.get_module(state.dependency).on_event(state, event)
    {:stop, new_state}
  end

  @impl Lifecycle
  def handle_info({DataStream, {stream, stream_data}}, %DependencyState{} = state) do
    new_state = handle_stream(state, stream, stream_data)
    {:stop, new_state}
  end

  @impl Lifecycle
  def handle_info(_message, %DependencyState{} = state), do: {:cont, state}

  @impl Lifecycle
  def handle_stop(_reason, %DependencyState{dependency: dependency} = state) do
    Dependency.broadcast_value(dependency, NotReady)
    {:cont, state}
  end

  @impl Lifecycle
  def handle_value_change(%DependencyState{value: value} = state, value), do: state

  def handle_value_change(%DependencyState{} = state, _old_value) do
    Dependency.broadcast_value(state.dependency, state.value)
    state
  end

  @spec put_dependencies(DependencyState.t(), Dependency.dependency_mapping()) ::
          DependencyState.t()
  defp put_dependencies(%DependencyState{} = state, mapping) do
    old_mapping = Map.get(state.private, __MODULE__, [])
    deps = Dependency.change_mapping(old_mapping, mapping, state.deps)

    state = %DependencyState{
      state
      | deps: deps,
        private: Map.put(state.private, __MODULE__, mapping)
    }

    if Enum.empty?(deps) do
      state
    else
      handle_dependency_change(state)
    end
  end

  @spec subscribe_to_events(DependencyState.t(), Enumerable.t()) :: DependencyState.t()
  defp subscribe_to_events(%DependencyState{} = state, events) do
    for event_module <- events do
      :ok = Emitter.subscribe(event_module)
    end

    state
  end

  defp subscribe_to_streams(%DependencyState{} = state, streams) do
    for stream <- streams do
      :ok = Emitter.subscribe(stream)
    end

    state
  end

  @spec handle_stream(DependencyState.t(), Dependency.dependency(), Operation.t()) ::
          DependencyState.t()
  defp handle_stream(%DependencyState{} = state, stream, %Operation.Batch{
         operations: operations
       }) do
    for operation <- operations, reduce: state do
      state -> handle_stream(state, stream, operation)
    end
  end

  defp handle_stream(%DependencyState{} = state, stream, stream_event) do
    Dependency.get_module(state.dependency).on_stream(state, {stream, stream_event})
  end

  @spec handle_dependency_change(DependencyState.t()) :: DependencyState.t()
  def handle_dependency_change(%DependencyState{deps: deps} = state) do
    missing_dependencies =
      deps
      |> Map.values()
      |> Enum.any?(&(&1 == NotReady))

    if missing_dependencies do
      Lifecycle.update_value(state, fn _ -> NotReady end)
    else
      Dependency.get_module(state.dependency).on_dependency_change(state)
    end
  end

  @spec handle_dependency_info(any(), DependencyState.t()) :: DependencyState.t()
  def handle_dependency_info({dependency, value}, %DependencyState{} = state) do
    key =
      state.dependency
      |> Dependency.get_module()
      |> get_config()
      |> Keyword.fetch!(:dependencies)
      |> Keyword.fetch!(dependency)

    put_in(state.deps[key], value)
    |> handle_dependency_change()
  end

  @doc """
  Validates configuration for the dependency and raises if it is invalid.
  Available configuration options:
  :dependencies (default []) - dependencies list
  :events (default []) - events to subscribe, where key is a module, and value is a topic
  """
  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
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
      ],
      streams: [
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
      def on_dependency_change(state) do
        module = Exshome.Dependency.get_module(state.dependency)

        Logger.warning("""
        Some module dependency changed.
        Please implement on_dependency_change/1 callback for #{module}
        """)

        state
      end

      @impl Subscription
      def on_event(%DependencyState{} = state, event) do
        module = Exshome.Dependency.get_module(state.dependency)

        Logger.warning("""
        Received unexpected event #{inspect(event)},
        Please implement on_event/2 callback for #{module}
        """)

        state
      end

      @impl Subscription
      def on_stream(%DependencyState{} = state, {_stream, stream_event}) do
        module = Exshome.Dependency.get_module(state.dependency)

        Logger.warning("""
        Received unexpected stream event #{inspect(stream_event)},
        Please implement on_stream/2 callback for #{module}
        """)

        state
      end

      defoverridable(on_dependency_change: 1, on_event: 2, on_stream: 2)
    end
  end
end
