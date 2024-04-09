defmodule ExshomePlayer.Variables.Volume do
  @moduledoc """
  Playback volume.
  """

  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Services.PlayerState

  use Exshome.Service.VariableService,
    app: ExshomePlayer,
    name: "player_volume",
    dependencies: [player: PlayerState],
    variable: [
      group: "player",
      type: Exshome.Datatype.Integer,
      validate: [
        min: 0,
        max: 100
      ]
    ]

  @impl DependencyServiceBehaviour
  def handle_dependency_change(%ServiceState{deps: %{player: %PlayerState{} = player}} = state) do
    volume = round(player.volume || 0)

    update_value(state, fn _ -> volume end)
  end

  @impl VariableServiceBehaviour
  def handle_set_value(value, %ServiceState{} = state) when is_integer(value) do
    Playback.set_volume(value)
    state
  end
end
