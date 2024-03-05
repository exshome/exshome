defmodule ExshomePlayer.Variables.Position do
  @moduledoc """
  Playback position.
  """

  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    app: ExshomePlayer,
    name: "player_position",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ],
    variable: [
      group: "player",
      type: Exshome.Datatype.Integer,
      validate: [
        min: 0
      ]
    ]

  @impl Subscription
  def on_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    position = round(player.time_pos || 0)
    duration = round(player.duration || 0)

    state
    |> update_value(fn _ -> position end)
    |> update_validations(&Map.put(&1, :max, duration))
  end

  @impl GenServerVariable
  def handle_set_value(%DependencyState{} = state, value) when is_integer(value) do
    Playback.seek(value)
    state
  end

  @impl GenServerVariable
  def not_ready_reason(%DependencyState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
