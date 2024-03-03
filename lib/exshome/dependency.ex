defmodule Exshome.Dependency do
  @moduledoc """
  Contains all dependency-related features.
  """
  alias Exshome.Behaviours.EmitterTypeBehaviour
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter

  @behaviour EmitterTypeBehaviour

  @impl EmitterTypeBehaviour
  def required_behaviours, do: MapSet.new([Exshome.Behaviours.GetValueBehaviour])

  @impl EmitterTypeBehaviour
  def validate_message!(_), do: :ok

  @type dependency() :: atom() | {atom(), String.t()}
  @type value() :: term() | NotReady
  @type dependency_key() :: atom()
  @type dependency_mapping() :: [{Emitter.id(), dependency_key()}]
  @type deps :: %{dependency_key() => value()}

  @callback get_value(dependency()) :: value()

  @spec get_value(Emitter.id()) :: value()
  def get_value(id), do: Emitter.get_module(id).get_value(id)

  @spec get_and_subscribe(Emitter.id()) :: value()
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

  @spec dependency_id(Emitter.id()) :: String.t()
  def dependency_id({module, id}) when is_atom(module) and is_binary(id),
    do: "#{dependency_id(module)}:#{id}"

  def dependency_id(module) when is_atom(module), do: inspect(module)

  @spec subscriptions() :: MapSet.t(Emitter.id())
  def subscriptions, do: Emitter.subscriptions() |> Map.get(__MODULE__, MapSet.new())

  defmacro __using__(_) do
    quote do
      use Exshome.Behaviours.EmitterBehaviour, type: Exshome.Dependency
      alias Exshome.Behaviours.GetValueBehaviour
      @behaviour GetValueBehaviour
    end
  end
end
