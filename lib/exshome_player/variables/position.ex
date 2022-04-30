defmodule ExshomePlayer.Variables.Position do
  @moduledoc """
  Playback position.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Dependency.GenServerDependency,
    name: "player_position",
    dependencies: [{PlayerState, :player}]

  @impl GenServerDependency
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    position = round(player.time_pos || 0)

    update_value(state, position)
  end
end
