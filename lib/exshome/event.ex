defmodule Exshome.Event do
  @moduledoc """
  Contains all event-related features.
  """
  @type event_module() :: atom()
  @type topic() :: :default | String.t()
  @type event_message() :: struct() | atom()

  @spec subscribe(event_module(), topic()) :: :ok
  def subscribe(event_module, topic \\ :default) do
    :ok =
      event_module
      |> pub_sub_topic(topic)
      |> Exshome.PubSub.subscribe()
  end

  @spec unsubscribe(event_module(), topic()) :: :ok
  def unsubscribe(event_module, topic \\ :default) do
    :ok =
      event_module
      |> pub_sub_topic(topic)
      |> Exshome.PubSub.unsubscribe()
  end

  @spec broadcast(event_message(), topic()) :: :ok
  def broadcast(event, topic \\ :default) do
    :ok =
      event
      |> pub_sub_topic(topic)
      |> Exshome.PubSub.broadcast({__MODULE__, event})
  end

  @spec pub_sub_topic(event_message(), topic()) :: String.t()
  defp pub_sub_topic(event_message, :default), do: base_topic_name(event_message)

  defp pub_sub_topic(event_message, topic) when is_binary(topic) do
    Enum.join(
      [
        base_topic_name(event_message),
        topic
      ],
      ":"
    )
  end

  @spec base_topic_name(event_message()) :: String.t()
  defp base_topic_name(%event_module{}), do: base_topic_name(event_module)

  defp base_topic_name(event_module) do
    raise_if_not_event_module!(event_module)
    event_module.name()
  end

  defp raise_if_not_event_module!(module) do
    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    correct_module = module_has_correct_behaviour && module_has_name

    if !correct_module do
      raise "#{inspect(module)} does not emit events!"
    end
  end

  defmacro __using__(name: name) do
    quote do
      alias Exshome.Event
      use Exshome.Named, "event:#{unquote(name)}"
      add_tag(Event)
    end
  end
end
