defmodule ExshomePlayer.PlayerState.Path do
  @moduledoc """
  Playback path.
  """

  alias ExshomePlayer.PlayerState

  use Exshome.Dependency.GenServerDependency,
    name: "player_path",
    dependencies: [{PlayerState, :player}]

  @impl GenServerDependency
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    update_value(state, player.path || "")
  end
end
