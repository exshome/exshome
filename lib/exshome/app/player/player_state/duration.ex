defmodule Exshome.App.Player.PlayerState.Duration do
  @moduledoc """
  Playback duration.
  """

  alias Exshome.App.Player.PlayerState

  use Exshome.Dependency.GenServerDependency,
    name: "player_duration",
    dependencies: [{PlayerState, :player}]

  @impl GenServerDependency
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    duration = round(player.duration || 0)

    update_value(state, duration)
  end
end
