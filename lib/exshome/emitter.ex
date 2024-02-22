defmodule Exshome.Emitter do
  @moduledoc """
  Generic event emitter.
  Allows to subscribe to specific emitter, and receive related messages.
  """

  alias Exshome.BehaviourMapping
  alias Exshome.PubSub

  @doc """
  Subscribes to specific emitter. Subscriber will receive every change to the mailbox.
  You can process these changes with `c:GenServer.handle_info/2` callback.

  Message format is a tuple `{emitter_module, message}`, where:
  - `emitter_module` is the specific emitter you have subscribed to;
  - `message` - related event. Depends on the specific emitter.
  """
  @spec subscribe(emitter_module :: module(), identifier :: term()) :: :ok
  def subscribe(emitter_module, identifier) do
    :ok = emitter_module |> pub_sub_topic(identifier) |> PubSub.subscribe()

    add_subscription(emitter_module, identifier)
  end

  @doc """
  Unsubscribe from specific emitter.
  Your process will no longer receive new updates, though it still may have some previous messages in the mailbox.
  """
  @spec unsubscribe(emitter_module :: module(), identifier :: term()) :: :ok
  def unsubscribe(emitter_module, identifier) do
    :ok = emitter_module |> pub_sub_topic(identifier) |> PubSub.unsubscribe()

    remove_subscription(emitter_module, identifier)
  end

  @doc """
  Broadcast changes for the emitter.
  """
  @spec broadcast(emitter_module :: module(), identifier :: term(), message :: term()) :: :ok
  def broadcast(emitter_module, identifier, message) do
    emitter_module
    |> pub_sub_topic(identifier)
    |> PubSub.broadcast({emitter_module, message})
  end

  @doc """
  Returns all subscriptions of the current process.
  """
  @spec subscriptions() :: %{module() => MapSet.t()}
  def subscriptions, do: Process.get(__MODULE__, %{})

  @spec add_subscription(module(), identifier :: term()) :: :ok
  defp add_subscription(emitter_module, identifier) do
    updated_subscriptions =
      Map.update(
        subscriptions(),
        emitter_module,
        MapSet.new([identifier]),
        &MapSet.put(&1, identifier)
      )

    Process.put(__MODULE__, updated_subscriptions)

    :ok
  end

  @spec remove_subscription(module(), identifier :: term()) :: :ok
  def remove_subscription(emitter_module, identifier) do
    updated_subsciptions =
      Map.update(
        subscriptions(),
        emitter_module,
        MapSet.new(),
        &MapSet.delete(&1, identifier)
      )

    Process.put(__MODULE__, updated_subsciptions)

    :ok
  end

  @spec pub_sub_topic(module(), term()) :: String.t()
  defp pub_sub_topic(emitter_module, identifier) do
    child_module = emitter_module.child_module(identifier)
    behaviour = emitter_module.child_behaviour()

    %{^behaviour => valid_children} = BehaviourMapping.behaviour_mapping()

    if !MapSet.member?(valid_children, child_module) do
      raise """
      #{inspect(child_module)} is not #{inspect(emitter_module)}.
      Please, implement a #{inspect(behaviour)}.
      """
    end

    Enum.join(
      [
        emitter_module.topic_prefix(),
        emitter_module.pub_sub_topic(identifier)
      ],
      ":"
    )
  end
end
