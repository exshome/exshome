defmodule Exshome.Dependency do
  @moduledoc """
  Contains all dependency-related features.
  """
  alias Exshome.Behaviours.EmitterTypeBehaviour
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias Exshome.Id

  @behaviour EmitterTypeBehaviour

  @impl EmitterTypeBehaviour
  def required_behaviours do
    MapSet.new([
      Exshome.Behaviours.GetValueBehaviour,
      Exshome.Behaviours.NamedBehaviour
    ])
  end

  @impl EmitterTypeBehaviour
  def validate_message!(_), do: :ok

  @type value() :: term() | NotReady
  @type dependency_key() :: atom()
  @type dependency_mapping() :: [{Id.t(), dependency_key()}]
  @type deps :: %{dependency_key() => value()}

  @callback get_value(Id.t()) :: value()

  @spec get_value(Id.t()) :: value()
  def get_value(id), do: Id.get_module(id).get_value(id)

  @spec get_and_subscribe(Id.t()) :: value()
  def get_and_subscribe(id) do
    result = get_value(id)

    :ok = Emitter.subscribe(id)

    case result do
      NotReady -> get_value(id)
      data -> data
    end
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
          :ok = Emitter.unsubscribe(dependency)
          Map.delete(acc, mapping_key)
      end

    keys_to_subscribe = MapSet.difference(new_keys, old_keys)

    for {dependency, mapping_key} <- new_mapping,
        MapSet.member?(keys_to_subscribe, dependency),
        reduce: deps do
      acc ->
        value = get_and_subscribe(dependency)
        Map.put(acc, mapping_key, value)
    end
  end

  @spec change_deps(
          old_mapping :: [{atom(), Id.t()}],
          new_mapping :: [{atom(), Id.t()}],
          old_deps :: deps()
        ) :: deps()
  def change_deps(old_mapping, new_mapping, deps) do
    old_deps = for {_, d} <- old_mapping, into: MapSet.new(), do: d
    new_deps = for {_, d} <- new_mapping, into: MapSet.new(), do: d

    deps_to_unsubscribe = MapSet.difference(old_deps, new_deps)

    deps =
      for {mapping_key, dependency} <- old_mapping,
          MapSet.member?(deps_to_unsubscribe, dependency),
          reduce: deps do
        acc ->
          :ok = Emitter.unsubscribe(dependency)
          Map.delete(acc, mapping_key)
      end

    deps_to_subscribe = MapSet.difference(new_deps, old_deps)

    for {mapping_key, dependency} <- new_mapping,
        MapSet.member?(deps_to_subscribe, dependency),
        reduce: deps do
      acc ->
        value = get_and_subscribe(dependency)
        Map.put(acc, mapping_key, value)
    end
  end

  @spec dependency_id(Id.t()) :: String.t()
  def dependency_id({module, id}) when is_atom(module) and is_binary(id),
    do: "#{dependency_id(module)}:#{id}"

  def dependency_id(module) when is_atom(module), do: module.get_name()

  @spec subscriptions() :: MapSet.t(Id.t())
  def subscriptions, do: Emitter.subscriptions() |> Map.get(__MODULE__, MapSet.new())
end
