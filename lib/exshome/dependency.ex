defmodule Exshome.Dependency do
  @moduledoc """
  Contains all dependency-related features.
  """
  alias Exshome.Dependency.NotReady

  @type dependency() :: atom() | {atom(), String.t()}
  @type value() :: term() | NotReady
  @type dependency_key() :: atom()
  @type dependency_mapping() :: [{dependency(), dependency_key()}]
  @type deps :: %{dependency_key() => value()}
  @type dependency_type() :: module()

  @callback get_value(dependency()) :: value()
  @callback type() :: dependency_type()

  @spec get_value(dependency()) :: value()
  def get_value(dependency) do
    raise_if_not_dependency!(__MODULE__, dependency)
    get_module(dependency).get_value(dependency)
  end

  @spec get_type(dependency()) :: dependency_type()
  def get_type(dependency) do
    raise_if_not_dependency!(__MODULE__, dependency)
    get_module(dependency).type()
  end

  @spec subscribe(dependency()) :: value()
  def subscribe(dependency) do
    result = get_value(dependency)

    :ok =
      dependency
      |> dependency_id()
      |> Exshome.PubSub.subscribe()

    :ok = add_subscription(dependency)

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

    remove_subscription(dependency)
  end

  @spec broadcast_value(dependency(), value()) :: :ok
  def broadcast_value(dependency, value) do
    id = dependency_id(dependency)
    type = get_type(dependency)
    Exshome.PubSub.broadcast(id, {type, {dependency, value}})
  end

  @spec get_module(dependency()) :: module()
  def get_module({module, id}) when is_binary(id), do: get_module(module)

  def get_module(module) when is_atom(module), do: module

  @spec dependency_id(dependency()) :: String.t()
  def dependency_id({module, id}) when is_binary(id) do
    Enum.join(
      [
        dependency_id(module),
        id
      ],
      ":"
    )
  end

  def dependency_id(dependency) do
    raise_if_not_dependency!(__MODULE__, dependency)
    get_module(dependency).name()
  end

  @spec change_mapping(
          old_mapping :: dependency_mapping(),
          new_mapping :: dependency_mapping(),
          old_deps :: deps()
        ) :: deps()
  def change_mapping(old_mapping, new_mapping, deps) do
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

  @spec raise_if_not_dependency!(module(), dependency()) :: nil
  def raise_if_not_dependency!(parent_module, dependency) do
    module = get_module(dependency)

    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(parent_module)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    module_has_type = function_exported?(module, :type, 0)
    module_is_dependency = module_has_correct_behaviour && module_has_name && module_has_type

    if !module_is_dependency do
      raise "#{inspect(module)} is not a #{inspect(parent_module)}!"
    end
  end

  @spec subscriptions() :: MapSet.t(dependency)
  def subscriptions, do: Process.get(__MODULE__, MapSet.new())

  @spec add_subscription(dependency()) :: :ok
  defp add_subscription(dependency) do
    Process.put(
      __MODULE__,
      MapSet.put(subscriptions(), dependency)
    )

    :ok
  end

  @spec remove_subscription(dependency()) :: :ok
  defp remove_subscription(dependency) do
    Process.put(
      __MODULE__,
      MapSet.delete(subscriptions(), dependency)
    )

    :ok
  end

  defmacro __using__(_) do
    quote do
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Exshome.Dependency)
      @behaviour Exshome.Dependency
    end
  end
end
