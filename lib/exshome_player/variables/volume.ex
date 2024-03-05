defmodule ExshomePlayer.Variables.Volume do
  @moduledoc """
  Playback volume.
  """

  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    app: ExshomePlayer,
    name: "player_volume",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ],
    variable: [
      group: "player",
      type: Exshome.Datatype.Integer,
      validate: [
        min: 0,
        max: 100
      ]
    ]

  @impl Subscription
  def on_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    volume = round(player.volume || 0)

    update_value(state, fn _ -> volume end)
  end

  @impl GenServerVariable
  def handle_set_value(%DependencyState{} = state, value) when is_integer(value) do
    Playback.set_volume(value)
    state
  end
end
