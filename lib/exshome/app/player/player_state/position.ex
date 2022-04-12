defmodule Exshome.App.Player.PlayerState.Position do
  @moduledoc """
  Playback position.
  """

  alias Exshome.App.Player

  use Exshome.Dependency.GenServerDependency,
    name: "player_position",
    dependencies: [{Player.MpvClient, :player}]

  @impl GenServerDependency
  def handle_dependency_change(
        %DependencyState{deps: %{player: %Player.PlayerState{} = player}} = state
      ) do
    update_value(state, player.time_pos || 0)
  end
end
