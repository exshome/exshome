defmodule ExshomePlayer.Services.PlayerState do
  @moduledoc """
  A module for storing a playback state for the MPV client.
  """

  alias __MODULE__
  alias Exshome.Emitter
  alias ExshomePlayer.Events.{MpvEvent, PlayerFileEndEvent, PlayerStateEvent}
  alias ExshomePlayer.Services.MpvSocket

  use Exshome.Dependency.GenServerDependency,
    name: "mpv_client",
    subscribe: [
      dependencies: [{MpvSocket, :socket}],
      events: [MpvEvent]
    ]

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

  @impl Subscription
  def on_dependency_change(%DependencyState{} = state) do
    if state.deps.socket == :connected do
      subscribe_to_player_state()
      update_value(state, fn _ -> %PlayerState{} end)
    else
      update_value(state, fn _ -> NotReady end)
    end
  end

  @impl Subscription
  def on_event(
        %DependencyState{} = state,
        {MpvEvent, {"property-change", %{"name" => name} = event}}
      ) do
    update_value(
      state,
      &Map.put(
        &1,
        property_mapping()[name],
        event["data"]
      )
    )
  end

  def on_event(
        %DependencyState{} = state,
        {MpvEvent, {"end-file", %{"reason" => reason}}}
      ) do
    Emitter.broadcast(PlayerFileEndEvent, reason)
    state
  end

  def on_event(%DependencyState{} = state, {MpvEvent, event}) do
    Emitter.broadcast(PlayerStateEvent, event)
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
