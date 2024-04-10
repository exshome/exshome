defmodule Exshome.Service.VariableService do
  @moduledoc """
  Variable backed by service.
  """
  alias Exshome.Behaviours.ServiceExtensionBehaviour
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias Exshome.Id
  alias Exshome.Service
  alias Exshome.Service.ServiceState
  alias Exshome.Variable
  alias Exshome.Variable.VariableConfig

  defstruct [:config, :data, :validations]

  @type t() :: %__MODULE__{
          config: keyword(),
          data: VariableConfig.t(),
          validations: %{}
        }

  @spec set_value(Id.t(), term()) :: :ok | {:error, String.t()}
  def set_value(id, value) do
    Service.call(id, {__MODULE__, :set_value, value})
  end

  @spec update_validations(ServiceState.t(), (map() -> map())) :: ServiceState.t()
  def update_validations(%ServiceState{} = state, update_fn) do
    state
    |> Service.update_private(__MODULE__, &update_in(&1.validations, update_fn))
    |> update_variable_info()
  end

  @spec variable_from_state(ServiceState.t()) :: VariableConfig.t()
  def variable_from_state(%ServiceState{} = state) do
    %__MODULE__{config: config} = Service.get_private(state, __MODULE__)

    %VariableConfig{
      service_id: state.id,
      id: Dependency.dependency_id(state.id),
      name: Keyword.fetch!(config, :name),
      group: Keyword.fetch!(config, :group),
      not_ready_reason: not_ready_reason(state),
      can_delete?: false,
      can_rename?: false,
      readonly?: Keyword.get(config, :readonly?, false),
      type: Keyword.fetch!(config, :type),
      validations: get_validations(state)
    }
  end

  defp not_ready_reason(%ServiceState{deps: deps, value: NotReady}) do
    missing_deps = for {key, NotReady} <- deps, do: key

    if Enum.any?(missing_deps) do
      "Missing dependencies: #{inspect(missing_deps)}"
    else
      "Variable is not started yet"
    end
  end

  defp not_ready_reason(%ServiceState{} = state), do: state.module.not_ready_reason(state)

  @spec get_validations(ServiceState.t()) :: map()
  defp get_validations(%ServiceState{} = state) do
    %__MODULE__{validations: validations} = Service.get_private(state, __MODULE__)

    validations
  end

  @behaviour ServiceExtensionBehaviour

  @impl ServiceExtensionBehaviour
  def validate_config!(config) do
    NimbleOptions.validate!(
      config,
      group: [
        type: :string,
        required: true
      ],
      name: [
        type: :string,
        required: true
      ],
      readonly?: [
        type: :boolean
      ],
      type: [
        type: :atom,
        required: true
      ],
      validate: [
        type: :keyword_list
      ]
    )

    :ok
  end

  @impl ServiceExtensionBehaviour
  def init(%ServiceState{} = state, config) do
    default_validations =
      config
      |> Keyword.get(:validate, [])
      |> Enum.into(%{})

    Service.update_private(
      state,
      __MODULE__,
      fn _ ->
        %__MODULE__{
          config: config,
          data: nil,
          validations: default_validations
        }
      end
    )
  end

  @impl ServiceExtensionBehaviour
  def after_init(%ServiceState{} = state), do: update_variable_info(state)

  @impl ServiceExtensionBehaviour
  def handle_value_change(_, %ServiceState{} = state), do: update_variable_info(state)

  defp update_variable_info(%ServiceState{} = state) do
    %__MODULE__{data: old_data} = Service.get_private(state, __MODULE__)
    %VariableConfig{} = new_data = state.module.variable_from_state(state)

    case {old_data, new_data} do
      {data, data} ->
        :ok

      {nil, _} ->
        :ok = Variable.register_variable_data(new_data)

      _ ->
        :ok = Variable.update_variable_data(new_data)
    end

    Service.update_private(state, __MODULE__, &%__MODULE__{&1 | data: new_data})
  end

  @impl ServiceExtensionBehaviour
  def handle_call({__MODULE__, :set_value, value}, _from, %ServiceState{} = state) do
    state = Id.get_module(state.id).handle_set_value(value, state)
    {:stop, {:ok, state}}
  end

  def handle_call(_, _, %ServiceState{} = state), do: {:cont, state}

  @impl ServiceExtensionBehaviour
  def handle_stop(_reason, %ServiceState{} = state) do
    %__MODULE__{data: data} = Service.get_private(state, __MODULE__)
    :ok = Variable.remove_variable_data(data)

    {:cont, state}
  end

  defmacro __using__(config) do
    name = Keyword.fetch!(config, :name)
    {settings, config} = Keyword.pop!(config, :variable)

    variable_service_extension = [
      {
        __MODULE__,
        Keyword.merge(settings, name: name)
      }
    ]

    updated_config =
      config
      |> Keyword.put_new(:prefix, "variable")
      |> Keyword.update(:extensions, variable_service_extension, fn previous ->
        variable_service_extension ++ previous
      end)

    quote do
      alias Exshome.Behaviours.VariableBehaviour
      alias Exshome.Behaviours.VariableServiceBehaviour
      alias Exshome.Service.VariableService

      use Exshome.Service.DependencyService, unquote(updated_config)

      @behaviour VariableServiceBehaviour

      @impl VariableServiceBehaviour
      def not_ready_reason(_), do: nil

      @impl VariableServiceBehaviour
      defdelegate variable_from_state(state), to: VariableService

      defoverridable VariableServiceBehaviour

      @behaviour VariableBehaviour

      @impl VariableBehaviour
      defdelegate set_value(id, value), to: VariableService

      defdelegate update_validations(state, update_fn), to: VariableService
    end
  end
end
