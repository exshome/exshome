defmodule Exshome.Variable do
  @moduledoc """
  This module represents generic API to use with variables.
  Each variable has own name, dependencies, datatype and value.
  It is also a dependency by itself, so you can subscribe to changes in variables.
  """
  use GenServer
  alias Exshome.Dependency.GenServerDependency
  alias Exshome.Dependency.GenServerDependency.State

  @callback update_value(State.t(), value :: any()) :: State.t()
  @callback handle_dependency_change(State.t()) :: State.t()

  defdelegate get_value(server), to: GenServerDependency

  defdelegate update_value(state, value), to: GenServerDependency

  @spec start_link(opts :: map()) :: GenServer.on_start()
  def start_link(opts) do
    GenServerDependency.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(%{module: module} = opts) when is_atom(module) do
    GenServerDependency.on_init(opts)
    dependencies = module.__config__()[:dependencies]

    state =
      GenServerDependency.subscribe_to_dependencies(
        %State{module: module, deps: %{}},
        dependencies
      )

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:get_value, _from, %State{} = state) do
    {:reply, state.value, state}
  end

  @impl GenServer
  def handle_info(message, state) do
    state = GenServerDependency.handle_dependency_info(message, state)

    {:noreply, state}
  end

  @impl GenServer
  def terminate(_reason, state), do: GenServerDependency.terminate(state)

  @doc """
  Validates configuration for the variable and raises if they are invalid.
  Available configuration options:
  :name (required) - name of the variable
  :datatype (required) - datatype for the variable
  :dependencies (default %{}) - dependencies of the variable
  """
  @spec validate_config(Keyword.t()) :: keyword()
  def validate_config(config) do
    NimbleOptions.validate!(
      config,
      name: [
        type: :string,
        required: true
      ],
      datatype: [
        type: :atom,
        required: true
      ],
      dependencies: [
        type: :keyword_list,
        keys: [
          *: [
            type: :atom
          ]
        ]
      ]
    )
  end

  defmacro __using__(config) do
    quote do
      alias unquote(__MODULE__)
      alias Exshome.Dependency.GenServerDependency.State
      use Exshome.Dependency
      use Exshome.Named, "variable_#{unquote(config[:name])}"
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Variable)

      @behaviour Variable
      @after_compile __MODULE__

      def __config__, do: unquote(config)

      def __after_compile__(_env, _bytecode),
        do: Variable.validate_config(__MODULE__.__config__())

      @impl Variable
      defdelegate update_value(state, value), to: Variable

      @impl Exshome.Dependency
      def get_value, do: Variable.get_value(__MODULE__)

      def start_link(opts), do: opts |> update_opts() |> Variable.start_link()

      def child_spec(opts), do: opts |> update_opts() |> Variable.child_spec()

      defp update_opts(%{} = opts) do
        Map.merge(opts, %{module: __MODULE__})
      end
    end
  end
end
