defmodule ExshomePlayer.Variables.Position do
  @moduledoc """
  Playback position.
  """

  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    name: "player_position",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ]

  @impl Subscription
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    position = round(player.time_pos || 0)

    update_value(state, position)
  end

  @impl Variable
  def set_value(%DependencyState{} = state, value) when is_integer(value) do
    Playback.seek(value)
    state
  end
end
