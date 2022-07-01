defmodule Exshome.Dependency do
  @moduledoc """
  Contains all dependency-related features.
  """
  alias Exshome.Dependency.NotReady

  @type dependency() :: atom()
  @type value :: term() | NotReady

  @callback get_value() :: value()

  @spec get_value(dependency()) :: value()
  def get_value(dependency) do
    raise_if_not_dependency!(dependency)
    dependency.get_value()
  end

  @spec subscribe(dependency()) :: value()
  def subscribe(dependency) do
    result = get_value(dependency)

    :ok =
      dependency
      |> dependency_id()
      |> Exshome.PubSub.subscribe()

    case result do
      NotReady -> get_value(dependency)
      data -> data
    end
  end

  @spec unsubscribe(dependency()) :: :ok
  def unsubscribe(dependency) do
    dependency
    |> dependency_id()
    |> Exshome.PubSub.unsubscribe()
  end

  @spec broadcast_value(dependency(), value()) :: :ok
  def broadcast_value(dependency, value) do
    dependency
    |> dependency_id()
    |> Exshome.PubSub.broadcast({__MODULE__, {dependency, value}})
  end

  @spec dependency_module(dependency()) :: module()
  def dependency_module(module) when is_atom(module), do: module

  @spec dependency_id(dependency()) :: String.t()
  def dependency_id(dependency) do
    raise_if_not_dependency!(dependency)
    dependency.name()
  end

  defp raise_if_not_dependency!(module) do
    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    module_is_dependency = module_has_correct_behaviour && module_has_name

    if !module_is_dependency do
      raise "#{inspect(module)} is not a dependency!"
    end
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
