defmodule ExshomeTest.Hooks.PubSub do
  @moduledoc """
  Custom hooks for testing pubsub.
  """

  alias ExshomeTest.TestRegistry

  def topic_name(topic) when is_binary(topic),
    do: "#{inspect(TestRegistry.get_parent())}_#{topic}"
end
