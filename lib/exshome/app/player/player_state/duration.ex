defmodule Exshome.App.Player.PlayerState.Duration do
  @moduledoc """
  Playback duration.
  """

  alias Exshome.App.Player

  use Exshome.Dependency.GenServerDependency,
    name: "player_duration",
    dependencies: [{Player.MpvClient, :player}]

  @impl GenServerDependency
  def handle_dependency_change(
        %DependencyState{deps: %{player: %Player.PlayerState{} = player}} = state
      ) do
    update_value(state, player.duration || 0)
  end
end
