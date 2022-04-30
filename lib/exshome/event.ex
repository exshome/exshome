defmodule Exshome.Event do
  @moduledoc """
  Contains all event-related features.
  """
  @type event_module() :: atom()
  @type event_message() :: struct() | atom()

  @spec subscribe(event_module()) :: :ok
  def subscribe(event_module) do
    :ok =
      event_module
      |> pub_sub_topic!()
      |> Exshome.PubSub.subscribe()
  end

  @spec unsubscribe(event_module()) :: :ok
  def unsubscribe(event_module) do
    :ok =
      event_module
      |> pub_sub_topic!()
      |> Exshome.PubSub.unsubscribe()
  end

  @spec broadcast(event_message()) :: :ok
  def broadcast(event) do
    :ok =
      event
      |> pub_sub_topic!()
      |> Exshome.PubSub.broadcast({__MODULE__, event})
  end

  @spec pub_sub_topic!(event_message()) :: String.t()
  defp pub_sub_topic!(%event_module{}), do: pub_sub_topic!(event_module)

  defp pub_sub_topic!(event_module) do
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
