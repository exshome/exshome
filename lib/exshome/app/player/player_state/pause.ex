defmodule Exshome.App.Player.PlayerState.Pause do
  @moduledoc """
  Playback pause data.
  """

  alias Exshome.App.Player

  use Exshome.Dependency.GenServerDependency,
    name: "player_pause",
    dependencies: [{Player.MpvClient, :player}]

  @impl GenServerDependency
  def handle_dependency_change(
        %DependencyState{deps: %{player: %Player.PlayerState{} = player}} = state
      ) do
    player_has_track = !player.path
    update_value(state, player_has_track || player.pause)
  end
end
