defmodule Exshome.DataStream do
  @moduledoc """
  Contains all DataStream-related features.
  """
  alias Exshome.DataStream.Operation

  @type stream_module() :: atom()
  @type topic() :: :default | String.t()
  @type stream_message() :: [Operation.t()]

  @spec subscribe(stream_module(), topic()) :: :ok
  def subscribe(stream_module, topic \\ :default) do
    :ok =
      stream_module
      |> pub_sub_topic(topic)
      |> Exshome.PubSub.subscribe()
  end

  @spec unsubscribe(stream_module(), topic()) :: :ok
  def unsubscribe(stream_module, topic \\ :default) do
    :ok =
      stream_module
      |> pub_sub_topic(topic)
      |> Exshome.PubSub.unsubscribe()
  end

  @spec broadcast(stream_module(), stream_message(), topic()) :: :ok
  def broadcast(stream_module, message, topic \\ :default) do
    :ok =
      stream_module
      |> pub_sub_topic(topic)
      |> Exshome.PubSub.broadcast({__MODULE__, message})
  end

  @spec pub_sub_topic(stream_module(), topic()) :: String.t()
  defp pub_sub_topic(stream_module, :default), do: base_topic_name(stream_module)

  defp pub_sub_topic(stream_message, topic) when is_binary(topic) do
    Enum.join(
      [
        base_topic_name(stream_message),
        topic
      ],
      ":"
    )
  end

  @spec base_topic_name(stream_module()) :: String.t()
  defp base_topic_name(stream_module) do
    raise_if_not_stream_module!(stream_module)
    stream_module.name()
  end

  defp raise_if_not_stream_module!(module) do
    module_has_correct_behaviour =
      Exshome.Tag.tag_mapping()
      |> Map.fetch!(__MODULE__)
      |> MapSet.member?(module)

    module_has_name = function_exported?(module, :name, 0)
    correct_module = module_has_correct_behaviour && module_has_name

    if !correct_module do
      raise "#{inspect(module)} is not a #{__MODULE__}!"
    end
  end

  defmacro __using__(name: name) do
    quote do
      alias Exshome.DataStream
      use Exshome.Named, "event:#{unquote(name)}"
      add_tag(DataStream)
    end
  end
end
