defmodule Exshome.Subscribable do
  @moduledoc """
  Generic algorithms for subscription services.
  """

  defmodule NotReady do
    @moduledoc """
    Shows that subscription is not ready.
    """
  end

  @type subscription() :: atom() | {atom(), String.t()}
  @type value() :: term() | NotReady
  @type subscription_key() :: atom()
  @type subscription_mapping() :: [{subscription(), subscription_key()}]
  @type subscriptions :: %{subscription_key() => value()}

  @callback get_value(subscription()) :: value()

  @spec get_value(module(), subscription()) :: value()
  def get_value(parent_module, subscription) when is_atom(parent_module) do
    raise_if_not_subscribable!(parent_module, subscription)
    get_module(subscription).get_value(subscription)
  end

  @spec subscribe(module(), subscription()) :: value()
  def subscribe(parent_module, subscription) do
    result = get_value(parent_module, subscription)

    :ok =
      parent_module
      |> subscription_id(subscription)
      |> Exshome.PubSub.subscribe()

    case result do
      NotReady -> get_value(parent_module, subscription)
      data -> data
    end
  end

  @spec unsubscribe(module(), subscription()) :: :ok
  def unsubscribe(parent_module, subscription) do
    parent_module
    |> subscription_id(subscription)
    |> Exshome.PubSub.unsubscribe()
  end

  @spec broadcast_value(module(), subscription(), value()) :: :ok
  def broadcast_value(parent_module, subscription, value) do
    parent_module
    |> subscription_id(subscription)
    |> Exshome.PubSub.broadcast({parent_module, {subscription, value}})
  end

  @spec get_module(subscription()) :: module()
  def get_module({module, id}) when is_binary(id), do: get_module(module)

  def get_module(module) when is_atom(module), do: module

  @spec subscription_id(module(), subscription()) :: String.t()
  def subscription_id(parent_module, {module, id}) when is_binary(id) do
    Enum.join(
      [
        subscription_id(parent_module, module),
        id
      ],
      ":"
    )
  end

  def subscription_id(parent_module, subscription) do
    raise_if_not_subscribable!(parent_module, subscription)
    get_module(subscription).name()
  end

  @spec change_subscriptions(
          module(),
          subscription_mapping(),
          subscription_mapping(),
          subscriptions()
        ) :: subscriptions()
  def change_subscriptions(parent_module, old_mapping, new_mapping, deps) do
    old_keys = for {k, _} <- old_mapping, into: MapSet.new(), do: k
    new_keys = for {k, _} <- new_mapping, into: MapSet.new(), do: k

    keys_to_unsubscribe = MapSet.difference(old_keys, new_keys)

    deps =
      for {subscription, mapping_key} <- old_mapping,
          MapSet.member?(keys_to_unsubscribe, subscription),
          reduce: deps do
        acc ->
          :ok = unsubscribe(parent_module, subscription)
          Map.delete(acc, mapping_key)
      end

    keys_to_subscribe = MapSet.difference(new_keys, old_keys)

    for {subscription, mapping_key} <- new_mapping,
        MapSet.member?(keys_to_subscribe, subscription),
        reduce: deps do
      acc ->
        value = subscribe(parent_module, subscription)
        Map.put(acc, mapping_key, value)
    end
  end

  @spec raise_if_not_subscribable!(module(), subscription()) :: nil
  def raise_if_not_subscribable!(parent_module, subscription) do
    module = get_module(subscription)

    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(parent_module)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    module_is_subscribable = module_has_correct_behaviour && module_has_name

    if !module_is_subscribable do
      raise "#{inspect(module)} is not a #{inspect(parent_module)}!"
    end
  end

  defmacro __using__(_) do
    quote do
      alias Exshome.Subscribable
      @behaviour Subscribable

      @spec subscribe(Subscribable.subscription()) :: Subscribable.value()
      def subscribe(subscription) do
        Subscribable.subscribe(__MODULE__, subscription)
      end

      @spec unsubscribe(Subscribable.subscription()) :: :ok
      def unsubscribe(subscription) do
        Subscribable.unsubscribe(__MODULE__, subscription)
      end

      @spec broadcast_value(Subscribable.subscription(), Subscribable.value()) :: :ok
      def broadcast_value(subscription, value) do
        Subscribable.broadcast_value(__MODULE__, subscription, value)
      end

      @spec get_module(Subscribable.subscription()) :: module()
      def get_module(subscription) do
        Subscribable.get_module(subscription)
      end

      @spec get_id(Subscribable.subscription()) :: String.t()
      def get_id(subscription) do
        Subscribable.subscription_id(__MODULE__, subscription)
      end

      @spec get_value(Subscribable.subscription()) :: Subscribable.value()
      def get_value(subscription) do
        Subscribable.get_value(__MODULE__, subscription)
      end

      @spec change_mapping(
              Subscribable.subscription_mapping(),
              Subscribable.subscription_mapping(),
              Subscribable.subscriptions()
            ) :: Subscribable.subscriptions()
      def change_mapping(old_mapping, new_mapping, deps) do
        Subscribable.change_subscriptions(__MODULE__, old_mapping, new_mapping, deps)
      end
    end
  end
end
