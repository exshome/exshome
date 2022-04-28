defmodule Exshome.App.Player.PlayerState do
  @moduledoc """
  A module for storing a playback state for the MPV client.
  """

  alias __MODULE__
  alias Exshome.App.Player.{MpvSocket, MpvSocketEvent, PlayerStateEvent}
  alias Exshome.Event

  use Exshome.Dependency.GenServerDependency,
    name: "mpv_client",
    dependencies: [{MpvSocket, :socket}],
    events: [MpvSocketEvent]

  @keys [
    :path,
    :pause,
    :volume,
    :duration,
    :time_pos,
    :metadata
  ]

  defstruct @keys

  @type t() :: %__MODULE__{
          path: String.t() | nil,
          pause: boolean() | nil,
          volume: float() | nil,
          duration: float() | nil,
          time_pos: float() | nil,
          metadata: map() | nil
        }

  @impl GenServerDependency
  def handle_dependency_change(%DependencyState{} = state) do
    if state.deps.socket == :connected do
      subscribe_to_player_state()
      update_value(state, %PlayerState{})
    else
      update_value(state, Dependency.NotReady)
    end
  end

  @impl GenServerDependency
  def handle_event(
        %MpvSocketEvent{type: "property-change", data: %{"name" => name} = event},
        %DependencyState{value: %PlayerState{} = value} = state
      ) do
    new_value =
      Map.put(
        value,
        property_mapping()[name],
        event["data"]
      )

    update_value(state, new_value)
  end

  def handle_event(%MpvSocketEvent{} = event, %DependencyState{} = state) do
    Event.broadcast(%PlayerStateEvent{data: event.data, type: event.type})
    state
  end

  @spec subscribe_to_player_state() :: term()
  defp subscribe_to_player_state do
    property_mapping()
    |> Map.keys()
    |> Enum.each(&observe_property/1)
  end

  defp observe_property(property) do
    %{} = MpvSocket.send_command(["observe_property", 1, property])
  end

  defp property_mapping do
    for key <- @keys, into: %{} do
      property_key = key |> Atom.to_string() |> String.replace(~r/_/, "-")
      {property_key, key}
    end
  end
end
