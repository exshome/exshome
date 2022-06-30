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
    topic
  end

  @hook_module Application.compile_env(:exshome, :hooks, [])[__MODULE__]
  if @hook_module do
    defoverridable(topic_name: 1)
    defdelegate topic_name(topic), to: @hook_module
  end
end
