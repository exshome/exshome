defmodule ExshomePlayer.Variables.Pause do
  @moduledoc """
  Playback pause data.
  """

  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Services.PlayerState

  use Exshome.Service.VariableService,
    app: ExshomePlayer,
    name: "player_pause",
    dependencies: [player: PlayerState],
    variable: [
      group: "player",
      type: Exshome.Datatype.Boolean
    ]

  @impl DependencyServiceBehaviour
  def handle_dependency_change(%ServiceState{deps: %{player: %PlayerState{} = player}} = state) do
    player_has_track = !player.path
    track_is_paused = player_has_track || player.pause
    update_value(state, fn _ -> track_is_paused end)
  end

  @impl VariableServiceBehaviour
  def handle_set_value(value, %ServiceState{} = state) when is_boolean(value) do
    if value, do: Playback.pause(), else: Playback.play()
    state
  end

  @impl VariableServiceBehaviour
  def not_ready_reason(%ServiceState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
