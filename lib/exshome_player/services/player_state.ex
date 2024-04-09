defmodule ExshomePlayer.Services.PlayerState do
  @moduledoc """
  A module for storing a playback state for the MPV client.
  """

  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias ExshomePlayer.Events.{MpvEvent, PlayerFileEndEvent, PlayerStateEvent}
  alias ExshomePlayer.Services.MpvSocket

  use Exshome.Service.DependencyService,
    app: ExshomePlayer,
    name: "mpv_client",
    dependencies: [
      socket: MpvSocket
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

  @impl ServiceBehaviour
  def init(%ServiceState{} = state) do
    :ok = Emitter.subscribe(MpvEvent)
    state
  end

  @impl DependencyServiceBehaviour
  def handle_dependency_change(%ServiceState{deps: deps} = state) do
    if deps.socket == :connected do
      subscribe_to_player_state()
      update_value(state, fn _ -> %__MODULE__{} end)
    else
      update_value(state, fn _ -> NotReady end)
    end
  end

  @impl DependencyServiceBehaviour
  def handle_event(
        {MpvEvent, {"property-change", %{"name" => name} = event}},
        %ServiceState{} = state
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

  def handle_event(
        {MpvEvent, {"end-file", %{"reason" => reason}}},
        %ServiceState{} = state
      ) do
    Emitter.broadcast(PlayerFileEndEvent, reason)
    state
  end

  def handle_event({MpvEvent, event}, %ServiceState{} = state) do
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
