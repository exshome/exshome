defmodule ExshomePlayer.Variables.Pause do
  @moduledoc """
  Playback pause data.
  """

  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable.GenServerVariable,
    app: ExshomePlayer,
    name: "player_pause",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ],
    variable: [
      group: "player",
      type: Exshome.Datatype.Boolean
    ]

  @impl Subscription
  def on_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    player_has_track = !player.path
    track_is_paused = player_has_track || player.pause
    update_value(state, fn _ -> track_is_paused end)
  end

  @impl GenServerVariable
  def handle_set_value(%DependencyState{} = state, value) when is_boolean(value) do
    if value, do: Playback.pause(), else: Playback.play()
    state
  end

  @impl GenServerVariable
  def not_ready_reason(%DependencyState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
