defmodule Exshome.DataStream.GenServerDataStream do
  @moduledoc """
  Common blocks for building gen-server data streams.
  """
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle

  use Lifecycle, key: :stream

  @impl Lifecycle
  def init_state(%DependencyState{} = state), do: state

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _) do
    module
    |> get_config()
    |> NimbleOptions.validate!([])
  end

  defmacro __using__(_) do
    quote do
      alias Exshome.DataStream.GenServerDataStream
      import Exshome.Dependency.GenServerDependency.Lifecycle, only: [register_hook_module: 1]
      register_hook_module(GenServerDataStream)
      alias Exshome.DataStream

      @after_compile {GenServerDataStream, :validate_module!}
    end
  end
end
