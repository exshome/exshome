defmodule ExshomePlayer.Variables.Duration do
  @moduledoc """
  Playback duration.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Service.VariableService,
    app: ExshomePlayer,
    name: "player_duration",
    dependencies: [player: PlayerState],
    variable: [
      group: "player",
      readonly?: true,
      type: Exshome.Datatype.Integer
    ]

  @impl DependencyServiceBehaviour
  def handle_dependency_change(%ServiceState{deps: %{player: %PlayerState{} = player}} = state) do
    duration = round(player.duration || 0)

    update_value(state, fn _ -> duration end)
  end

  @impl VariableServiceBehaviour
  def not_ready_reason(%ServiceState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
