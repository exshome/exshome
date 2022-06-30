defmodule ExshomePlayer.Variables.Pause do
  @moduledoc """
  Playback pause data.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    name: "player_pause",
    dependencies: [{PlayerState, :player}]

  @impl Workflow
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    player_has_track = !player.path
    update_value(state, player_has_track || player.pause)
  end
end
