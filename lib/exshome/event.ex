defmodule Exshome.Event do
  @moduledoc """
  Contains all event-related features.
  """
  @type event_module() :: atom()
  @type topic() :: String.t()
  @type event() :: term()
  @type event_message() :: {event_module(), topic(), event()}

  @spec subscribe(event_module(), topic()) :: :ok
  def subscribe(event_module, topic) do
    :ok =
      event_module
      |> pub_sub_topic!(topic)
      |> Exshome.PubSub.subscribe()
  end

  @spec unsubscribe(event_module(), topic()) :: :ok
  def unsubscribe(event_module, topic) do
    :ok =
      event_module
      |> pub_sub_topic!(topic)
      |> Exshome.PubSub.unsubscribe()
  end

  @spec broadcast_event(event_module(), topic(), event()) :: :ok
  def broadcast_event(event_module, topic, event) do
    :ok =
      event_module
      |> pub_sub_topic!(topic)
      |> Exshome.PubSub.broadcast({__MODULE__, {event_module, topic, event}})
  end

  @spec pub_sub_topic!(event_module(), topic()) :: String.t()
  defp pub_sub_topic!(event_module, topic) when is_binary(topic) do
    raise_if_not_event_module!(event_module)
    available_topics = event_module.__topics__()
    correct_topic = topic in available_topics

    if !correct_topic do
      raise """
      unknown topic #{topic} for #{inspect(event_module)}!
      Available topics are: #{available_topics}
      """
    end

    "#{event_module.name()}|#{topic}"
  end

  defp raise_if_not_event_module!(module) do
    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    module_has_topics = function_exported?(module, :__topics__, 0)
    correct_module = module_has_correct_behaviour && module_has_name && module_has_topics

    if !correct_module do
      raise "#{inspect(module)} does not emit events!"
    end
  end

  @spec validate_module!(Macro.Env.t(), String.t()) :: :ok
  def validate_module!(%Macro.Env{} = env, _bytecode) do
    topics = env.module.__topics__()
    validate_topics!(topics)
  end

  @doc """
  Validates list of topics for a module.
  Raises if it is invalid.
  """
  @spec validate_topics!(list(String.t())) :: :ok
  def validate_topics!(topics) when is_list(topics) do
    if Enum.empty?(topics) do
      raise "Topics should not be empty!"
    end

    wrong_type_topics = Enum.reject(topics, &is_binary/1)

    if !Enum.empty?(wrong_type_topics) do
      raise "Topic name should be a string, these have invalid types: #{inspect(wrong_type_topics)}"
    end

    duplicate_topics =
      topics
      |> Enum.frequencies()
      |> Enum.filter(fn {_key, value} -> value > 1 end)
      |> Enum.map(fn {key, _value} -> key end)

    if !Enum.empty?(duplicate_topics) do
      raise "duplicate topics: #{duplicate_topics}"
    end

    :ok
  end

  defmacro __using__(topics: topics) do
    quote do
      alias Exshome.Event
      @after_compile {Event, :validate_module!}
      import Exshome.Tag, only: [add_tag: 1]
      add_tag(Event)

      def __topics__, do: unquote(topics)
    end
  end
end
