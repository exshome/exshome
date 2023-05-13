defmodule Exshome.Event do
  @moduledoc """
  Contains all event-related features.
  """
  alias Exshome.Dependency

  @type event_message() :: struct() | atom()
  @type event_payload() :: {event_message(), String.t()} | event_message()

  @spec broadcast(event_payload()) :: :ok
  def broadcast(event) do
    dependency = to_dependency(event)
    value = to_value(event)
    :ok = Dependency.broadcast_value(dependency, value)
  end

  @spec to_dependency(event_payload()) :: Dependency.dependency()
  defp to_dependency({message, topic}) when is_binary(topic) do
    {to_dependency(message), topic}
  end

  defp to_dependency(event_payload) do
    module = get_module(event_payload)
    Dependency.raise_if_not_dependency!(__MODULE__, module)
    module
  end

  @spec get_module(event_message()) :: module()
  defp get_module(event_payload) when is_atom(event_payload), do: event_payload
  defp get_module(%event_module{}), do: event_module

  @spec to_value(event_payload()) :: event_message()
  defp to_value({message, _}), do: message
  defp to_value(message), do: message

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
