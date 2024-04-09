defmodule Exshome.Service.DependencyService do
  @moduledoc """
  Depencency backed by the service.
  """

  alias Exshome.Behaviours.ServiceExtensionBehaviour
  alias Exshome.DataStream
  alias Exshome.Dependency
  alias Exshome.Emitter
  alias Exshome.Id
  alias Exshome.Service
  alias Exshome.Service.ServiceState

  defstruct [:config, :dependencies, :dependency_mapping]

  @type t() :: %__MODULE__{
          config: keyword(),
          dependencies: keyword,
          dependency_mapping: %{Id.t() => [atom()]}
        }

  @behaviour ServiceExtensionBehaviour

  @impl ServiceExtensionBehaviour
  def validate_config!(config) do
    NimbleOptions.validate!(
      config,
      app: [
        type: :atom,
        required: true
      ],
      name: [
        type: :string,
        required: true
      ],
      dependencies: [
        type: :keyword_list
      ],
      prefix: [
        type: :string
      ],
      parent_module: [
        type: :atom
      ],
      extensions: [
        type: :keyword_list
      ]
    )

    :ok
  end

  @impl ServiceExtensionBehaviour
  def init(%ServiceState{} = state, config) do
    dependencies = Keyword.get(config, :dependencies, [])

    settings = %__MODULE__{
      config: config,
      dependencies: dependencies,
      dependency_mapping: Enum.group_by(dependencies, &elem(&1, 1), &elem(&1, 0))
    }

    %ServiceState{state | deps: %{}}
    |> Service.update_private(__MODULE__, fn _ -> settings end)
  end

  @impl ServiceExtensionBehaviour
  def after_init(%ServiceState{} = state) do
    %__MODULE__{dependencies: dependencies} = Service.get_private(state, __MODULE__)

    deps = Dependency.change_deps([], dependencies, %{})

    %ServiceState{state | deps: deps}
    |> maybe_process_dependency_updates()
  end

  @impl ServiceExtensionBehaviour
  def handle_call({__MODULE__, :get_value}, _, %ServiceState{value: value} = state) do
    {:stop, {value, state}}
  end

  def handle_call(_, _, %ServiceState{} = state), do: {:cont, state}

  @impl ServiceExtensionBehaviour
  def handle_info({Dependency, {id, value}}, %ServiceState{} = state) do
    %__MODULE__{dependency_mapping: mapping} =
      Service.get_private(state, __MODULE__)

    if Map.has_key?(mapping, id) do
      updates = Map.from_keys(mapping[id], value)
      deps = Map.merge(state.deps, updates)

      state =
        %ServiceState{state | deps: deps}
        |> maybe_process_dependency_updates()

      {:stop, state}
    else
      state = state.module.handle_service({id, value}, state)
      {:stop, state}
    end
  end

  def handle_info({DataStream, {id, operation}}, %ServiceState{} = state) do
    state =
      case operation do
        %DataStream.Operation.Batch{operations: operations} ->
          for op <- operations, reduce: state do
            state -> state.module.handle_stream({id, op}, state)
          end

        _ ->
          state.module.handle_stream({id, operation}, state)
      end

    {:stop, state}
  end

  def handle_info({Exshome.Event, event}, %ServiceState{} = state) do
    state = state.module.handle_event(event, state)

    {:stop, state}
  end

  def handle_info(_, %ServiceState{} = state), do: {:cont, state}

  @impl ServiceExtensionBehaviour
  def handle_value_change(value, %ServiceState{value: value} = state), do: state

  def handle_value_change(_, %ServiceState{value: new_value} = state) do
    :ok = Emitter.broadcast(state.id, new_value)
    state
  end

  @doc """
  Gets a value of the service.
  """
  @spec get_value(Id.t()) :: term()
  def get_value(id), do: Service.call(id, {__MODULE__, :get_value})

  @spec maybe_process_dependency_updates(ServiceState.t()) :: ServiceState.t()
  defp maybe_process_dependency_updates(%ServiceState{} = state) when state.deps == %{},
    do: state

  defp maybe_process_dependency_updates(%ServiceState{deps: deps} = state) do
    missing_deps = Enum.any?(deps, fn {_, value} -> value == Dependency.NotReady end)

    if missing_deps do
      Service.update_value(state, fn _ -> Dependency.NotReady end)
    else
      state.module.handle_dependency_change(state)
    end
  end

  defmacro __using__(config) do
    quote do
      alias Exshome.Behaviours.DependencyServiceBehaviour
      alias Exshome.Behaviours.ServiceBehaviour
      alias Exshome.Service.DependencyService
      alias Exshome.Service.ServiceState

      import Exshome.Service, only: [update_value: 2, update_data: 2]

      @behaviour Exshome.Behaviours.NamedBehaviour
      @impl Exshome.Behaviours.NamedBehaviour
      def get_name do
        unquote("#{Keyword.get(config, :prefix, "dependency")}:#{Keyword.fetch!(config, :name)}")
      end

      @behaviour Exshome.Behaviours.EmitterBehaviour
      @impl Exshome.Behaviours.EmitterBehaviour
      def emitter_type, do: Exshome.Dependency

      @behaviour Exshome.Behaviours.GetValueBehaviour
      @impl Exshome.Behaviours.GetValueBehaviour
      def get_value(id), do: DependencyService.get_value(id)

      @behaviour Exshome.Behaviours.BelongsToAppBehaviour
      @impl Exshome.Behaviours.BelongsToAppBehaviour
      def app, do: unquote(Keyword.fetch!(config, :app))

      @behaviour ServiceBehaviour

      @impl ServiceBehaviour
      def get_parent_module, do: unquote(Keyword.get(config, :parent_module, __CALLER__.module))

      @impl ServiceBehaviour
      def init(state), do: state

      @impl ServiceBehaviour
      def service_settings(_id) do
        [
          {
            Exshome.Service.DependencyService,
            unquote(config)
          }
        ] ++ unquote(Keyword.get(config, :extensions, []))
      end

      @impl ServiceBehaviour
      def not_ready_value, do: Exshome.Dependency.NotReady

      @impl ServiceBehaviour
      def handle_stop(_reason, %ServiceState{} = state), do: state

      defoverridable ServiceBehaviour

      @behaviour DependencyServiceBehaviour

      def child_spec(%{} = opts) do
        opts = Map.put_new(opts, :id, __MODULE__)

        %{
          id: opts.id,
          start: {Exshome.Service, :start_link, [opts]}
        }
      end
    end
  end
end
