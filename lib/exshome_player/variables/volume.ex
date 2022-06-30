defmodule ExshomePlayer.Variables.Volume do
  @moduledoc """
  Playback volume.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    name: "player_volume",
    dependencies: [{PlayerState, :player}]

  @impl Workflow
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    volume = round(player.volume || 0)

    update_value(state, volume)
  end
end
