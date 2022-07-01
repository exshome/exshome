defmodule ExshomePlayer.Variables.Path do
  @moduledoc """
  Playback path.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    name: "player_path",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ],
    variable: [
      readonly: true
    ]

  @impl Subscription
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    update_value(state, player.path || "")
  end
end
