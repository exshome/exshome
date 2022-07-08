defmodule ExshomePlayer.Variables.Pause do
  @moduledoc """
  Playback pause data.
  """

  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    name: "player_pause",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ],
    variable: [
      type: Exshome.DataType.Boolean
    ]

  @impl Subscription
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    player_has_track = !player.path
    update_value(state, player_has_track || player.pause)
  end

  @impl Variable
  def set_value(%DependencyState{} = state, value) when is_boolean(value) do
    if value, do: Playback.pause(), else: Playback.play()
    state
  end
end
