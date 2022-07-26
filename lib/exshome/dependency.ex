defmodule Exshome.Dependency do
  @moduledoc """
  Contains all dependency-related features.
  """
  alias Exshome.Dependency.NotReady

  @type dependency() :: atom() | {atom(), String.t()}
  @type value :: term() | NotReady
  @type dependency_key :: atom()
  @type depenency_mapping :: [{dependency(), dependency_key()}]
  @type deps :: %{dependency_key() => value()}

  @callback get_value(dependency()) :: value()

  @spec get_value(dependency()) :: value()
  def get_value(dependency) do
    raise_if_not_dependency!(dependency)
    dependency_module(dependency).get_value(dependency)
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
  def dependency_module({module, id}) when is_binary(id), do: dependency_module(module)

  def dependency_module(module) when is_atom(module), do: module

  @spec dependency_id(dependency()) :: String.t()
  def dependency_id({module, id}) when is_binary(id) do
    Enum.join([dependency_id(module), id], ":")
  end

  def dependency_id(dependency) do
    raise_if_not_dependency!(dependency)
    dependency.name()
  end

  @spec change_dependencies(depenency_mapping(), depenency_mapping(), deps()) :: deps()
  def change_dependencies(old_mapping, new_mapping, deps) do
    old_keys = for {k, _} <- old_mapping, into: MapSet.new(), do: k
    new_keys = for {k, _} <- new_mapping, into: MapSet.new(), do: k

    keys_to_unsubscribe = MapSet.difference(old_keys, new_keys)

    deps =
      for {dependency, mapping_key} <- old_mapping,
          MapSet.member?(keys_to_unsubscribe, dependency),
          reduce: deps do
        acc ->
          :ok = unsubscribe(dependency)
          Map.delete(acc, mapping_key)
      end

    keys_to_subscribe = MapSet.difference(new_keys, old_keys)

    for {dependency, mapping_key} <- new_mapping,
        MapSet.member?(keys_to_subscribe, dependency),
        reduce: deps do
      acc ->
        value = subscribe(dependency)
        Map.put(acc, mapping_key, value)
    end
  end

  defp raise_if_not_dependency!({module, id}) when is_atom(module) and is_binary(id) do
    raise_if_not_dependency!(module)
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
