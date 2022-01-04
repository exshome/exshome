defmodule Exshome.PubSub do
  @moduledoc """
  This module is responsible for broadcasting data inside application.
  """

  alias Phoenix.PubSub

  @spec subscribe(String.t()) :: :ok
  def subscribe(topic) when is_binary(topic) do
    :ok = PubSub.subscribe(__MODULE__, topic_name(topic))
  end

  @spec unsubscribe(String.t()) :: :ok
  def unsubscribe(topic) when is_binary(topic) do
    :ok = PubSub.unsubscribe(__MODULE__, topic_name(topic))
  end

  @spec broadcast(topic :: String.t(), message :: any()) :: :ok
  def broadcast(topic, message) when is_binary(topic) do
    :ok = PubSub.broadcast!(__MODULE__, topic_name(topic), message)
  end

  def topic_name(topic) when is_binary(topic) do
    topic_name_fn = Application.get_env(:exshome, __MODULE__)
    (topic_name_fn && topic_name_fn.(topic)) || topic
  end

  defmacro __using__(pubsub_key: key, fields: fields) do
    keys = Keyword.keys(fields)

    quote do
      defstruct unquote(keys)

      @type t() :: %__MODULE__{unquote_splicing(fields)}

      @spec broadcast(t()) :: :ok
      def broadcast(%__MODULE__{} = value), do: Exshome.PubSub.broadcast(unquote(key), value)

      @spec subscribe() :: t()
      def subscribe do
        :ok = Exshome.PubSub.subscribe(unquote(key))
        __MODULE__.get_state()
      end

      @spec unsubscribe() :: :ok
      def unsubscribe, do: Exshome.PubSub.unsubscribe(unquote(key))

      @spec get_state() :: t()
      def get_state do
        raise NotImplemented
      end

      defoverridable(get_state: 0)
    end
  end
end
