defmodule ExshomePlayer.Variables.Duration do
  @moduledoc """
  Playback duration.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    name: "player_duration",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ],
    variable: [
      readonly: true,
      type: Exshome.DataType.Integer
    ]

  @impl Subscription
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    duration = round(player.duration || 0)

    update_value(state, duration)
  end

  @impl Variable
  def not_ready_reason(%DependencyState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
