defmodule Exshome.Emitter do
  @moduledoc """
  Generic event emitter.
  Allows to subscribe to specific emitter, and receive related messages.
  """

  alias Exshome.BehaviourMapping
  alias Exshome.Behaviours.EmitterBehaviour
  alias Exshome.PubSub

  @type id() :: module() | {module(), String.t()}

  @doc """
  Subscribes to specific emitter. Subscriber will receive every change to the mailbox.
  You can process these changes with `c:GenServer.handle_info/2` callback.

  Message format is a tuple `{emitter_module, message}`, where:
  - `emitter_module` is the specific emitter you have subscribed to;
  - `message` - related event. Depends on the specific emitter.
  """
  @spec subscribe(id()) :: :ok
  def subscribe(id) do
    :ok = id |> pub_sub_topic() |> PubSub.subscribe()

    add_subscription(id)
  end

  @doc """
  Unsubscribe from specific emitter.
  Your process will no longer receive new updates, though it still may have some previous messages in the mailbox.
  """
  @spec unsubscribe(id()) :: :ok
  def unsubscribe(id) do
    :ok = id |> pub_sub_topic() |> PubSub.unsubscribe()

    remove_subscription(id)
  end

  @doc """
  Broadcast changes for the emitter.
  """
  @spec broadcast(id(), message :: term()) :: :ok
  def broadcast(id, message) do
    type = identifier_type(id)

    :ok = type.validate_message!(message)

    id
    |> pub_sub_topic()
    |> PubSub.broadcast({type, {id, message}})
  end

  @doc """
  Returns all subscriptions of the current process.
  """
  @spec subscriptions() :: %{module() => MapSet.t()}
  def subscriptions, do: Process.get(__MODULE__, %{})

  @spec add_subscription(id()) :: :ok
  defp add_subscription(id) do
    updated_subscriptions =
      Map.update(
        subscriptions(),
        identifier_type(id),
        MapSet.new([id]),
        &MapSet.put(&1, id)
      )

    Process.put(__MODULE__, updated_subscriptions)

    :ok
  end

  @doc """
  Extracts a module from emitter id.
  """
  @spec get_module(id()) :: module()
  def get_module({module, _}) when is_atom(module), do: module
  def get_module(module) when is_atom(module), do: module

  @spec remove_subscription(id()) :: :ok
  def remove_subscription(id) do
    updated_subsciptions =
      Map.update(
        subscriptions(),
        identifier_type(id),
        MapSet.new(),
        &MapSet.delete(&1, id)
      )

    Process.put(__MODULE__, updated_subsciptions)

    :ok
  end

  @spec identifier_type(id()) :: module()
  defp identifier_type({module, _}), do: identifier_type(module)
  defp identifier_type(module) when is_atom(module), do: module.emitter_type()

  @spec pub_sub_topic(id()) :: String.t()
  defp pub_sub_topic({module, identifier}) when is_atom(module) and is_binary(identifier) do
    Enum.join([pub_sub_topic(module), identifier], ":")
  end

  defp pub_sub_topic(module) when is_atom(module) do
    type = module.emitter_type()
    required = type.required_behaviours() |> MapSet.put(EmitterBehaviour)
    actual = BehaviourMapping.module_behaviours(module)
    missing_behaviours = MapSet.difference(required, actual)

    if Enum.any?(missing_behaviours) do
      raise """
      Module #{inspect(module)} is not a #{inspect(type)}.
      Please, implement a #{inspect(MapSet.to_list(missing_behaviours))}.
      """
    end

    Atom.to_string(module)
  end
end
