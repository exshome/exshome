defmodule Exshome.DataStream.GenServerDataStream do
  @moduledoc """
  Common blocks for building gen-server data streams.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency.GenServerDependency.DependencyState
  alias Exshome.Dependency.GenServerDependency.Lifecycle
  alias Exshome.Dependency.NotReady

  use Lifecycle, key: :stream

  @impl Lifecycle
  def init_state(%DependencyState{} = state), do: state

  @spec validate_module!(Macro.Env.t(), String.t()) :: keyword()
  def validate_module!(%Macro.Env{module: module}, _) do
    module
    |> get_config()
    |> NimbleOptions.validate!([])
  end

  @spec prepare_get_value_result(list() | NotReady) :: NotReady | Operation.ReplaceAll.t()
  def prepare_get_value_result(NotReady), do: NotReady

  def prepare_get_value_result(data) when is_list(data) do
    %Operation.ReplaceAll{data: data}
  end

  defmacro __using__(config) do
    quote do
      use Exshome.Dependency.GenServerDependency, unquote(config)
      use Exshome.Named, "data_stream:#{unquote(config[:name])}"
      alias Exshome.DataStream.GenServerDataStream
      import Exshome.Dependency.GenServerDependency.Lifecycle, only: [register_hook_module: 1]
      register_hook_module(GenServerDataStream)
      use Exshome.DataStream

      @after_compile {GenServerDataStream, :validate_module!}

      @impl Exshome.Dependency
      def type, do: Exshome.DataStream

      def get_value(dependency) do
        result = super(dependency)
        GenServerDataStream.prepare_get_value_result(result)
      end
    end
  end
end
