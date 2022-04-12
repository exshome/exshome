defmodule Exshome.App.Player.PlayerState.Volume do
  @moduledoc """
  Playback volume.
  """

  alias Exshome.App.Player

  use Exshome.Dependency.GenServerDependency,
    name: "player_volume",
    dependencies: [{Player.MpvClient, :player}]

  @impl GenServerDependency
  def handle_dependency_change(
        %DependencyState{deps: %{player: %Player.PlayerState{} = player}} = state
      ) do
    update_value(state, player.volume)
  end
end
