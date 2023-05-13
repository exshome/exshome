defmodule Exshome.Event do
  @moduledoc """
  Contains all event-related features.
  """
  alias Exshome.Dependency

  @type event_message() :: struct() | atom()
  @type event_topic() :: String.t() | :default

  @spec broadcast(event_message(), event_topic()) :: :ok
  def broadcast(event, topic \\ :default) do
    :ok =
      event
      |> event_to_dependency(topic)
      |> Dependency.broadcast_value(event)
  end

  @spec event_to_dependency(event_message(), event_topic()) :: Dependency.dependency()
  defp event_to_dependency(message, topic) when is_binary(topic) do
    {event_to_dependency(message, :default), topic}
  end

  defp event_to_dependency(event_payload, :default) do
    module = get_module(event_payload)
    Dependency.raise_if_not_dependency!(__MODULE__, module)
    module
  end

  @spec get_module(event_message()) :: module()
  defp get_module(event_payload) when is_atom(event_payload), do: event_payload
  defp get_module(%event_module{}), do: event_module

  defmacro __using__(name: name) do
    quote do
      alias Exshome.Event
      use Exshome.Named, "event:#{unquote(name)}"
      use Exshome.Dependency, type: Event
      add_tag(Event)

      @impl Dependency
      def get_value(_), do: :ok
    end
  end
end
