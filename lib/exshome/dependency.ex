defmodule Exshome.Dependency do
  @moduledoc """
  Contains all dependency-related features.
  """
  alias Exshome.Dependency.NotReady

  @type dependency() :: atom()
  @type get_value_result :: term() | NotReady

  @callback get_value() :: get_value_result()

  defmodule State do
    @moduledoc """
    Inner state for each dependency.
    """

    defstruct [:value, :module, :opts, :deps]

    @type t() :: %__MODULE__{
            module: module(),
            value: Exshome.Dependency.get_value_result(),
            opts: any(),
            deps: map()
          }
  end

  @spec get_value(dependency()) :: get_value_result()
  def get_value(dependency) do
    raise_if_not_dependency!(dependency)
    dependency.get_value()
  end

  @spec get_pid(atom() | pid()) :: pid() | nil
  def get_pid(server) when is_atom(server), do: Process.whereis(server)

  def get_pid(server) when is_pid(server) do
    if Process.alive?(server), do: server, else: nil
  end

  @spec subscribe(dependency()) :: get_value_result()
  def subscribe(dependency) do
    result = get_value(dependency)
    :ok = Exshome.PubSub.subscribe(dependency.name())

    case result do
      NotReady -> get_value(dependency)
      data -> data
    end
  end

  @spec unsubscribe(dependency()) :: :ok
  def unsubscribe(dependency) do
    raise_if_not_dependency!(dependency)
    Exshome.PubSub.unsubscribe(dependency.name())
  end

  defp raise_if_not_dependency!(module) do
    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)

    if !(module_has_correct_behaviour && module_has_name) do
      raise "#{inspect(module)} is not a dependency!"
    end
  end

  def broadcast_value(dependency, value) do
    raise_if_not_dependency!(dependency)
    Exshome.PubSub.broadcast(dependency.name(), {dependency, value})
  end

  @hook_module Application.compile_env(:exshome, :dependency_hook_module)
  if @hook_module do
    defoverridable(get_pid: 1)
    defdelegate get_pid(server), to: @hook_module
  end

  defmacro __using__(_) do
    quote do
      alias Exshome.Dependency
      @behaviour Dependency
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Dependency)
    end
  end
end
