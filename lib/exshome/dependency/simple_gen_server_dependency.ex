defmodule Exshome.Dependency.SimpleGenServerDependency do
  @moduledoc """
  This module stores generic API for GenServer based dependencies.
  """

  alias Exshome.Dependency
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  use Lifecycle, key: :simple_dependency

  @impl Lifecycle
  def init_state(%DependencyState{} = state), do: state

  @impl Lifecycle
  def handle_value_change(%DependencyState{value: value} = state, value), do: state

  def handle_value_change(%DependencyState{} = state, _old_value) do
    Dependency.broadcast_value(state.dependency, state.value)
    state
  end

  defmacro __using__(config) do
    quote do
      alias Exshome.Dependency.SimpleGenServerDependency

      use Exshome.Dependency.GenServerDependency, unquote(config)
      use Exshome.Named, "dependency:#{unquote(config[:name])}"
      import Exshome.Dependency.GenServerDependency.Lifecycle, only: [register_hook_module: 1]

      register_hook_module(SimpleGenServerDependency)

      @impl Exshome.Dependency
      def type, do: Exshome.Dependency
    end
  end
end
