defmodule ExshomePlayer.PlayerState.Volume do
  @moduledoc """
  Playback volume.
  """

  alias ExshomePlayer.PlayerState

  use Exshome.Dependency.GenServerDependency,
    name: "player_volume",
    dependencies: [{PlayerState, :player}]

  @impl GenServerDependency
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    volume = round(player.volume || 0)

    update_value(state, volume)
  end
end
