defmodule ExshomePlayer.Variables.Position do
  @moduledoc """
  Playback position.
  """

  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Services.PlayerState

  use Exshome.Service.VariableService,
    app: ExshomePlayer,
    name: "player_position",
    dependencies: [player: PlayerState],
    variable: [
      group: "player",
      type: Exshome.Datatype.Integer,
      validate: [
        min: 0
      ]
    ]

  @impl DependencyServiceBehaviour
  def handle_dependency_change(%ServiceState{deps: %{player: %PlayerState{} = player}} = state) do
    position = round(player.time_pos || 0)
    duration = round(player.duration || 0)

    state
    |> update_value(fn _ -> position end)
    |> update_validations(&Map.put(&1, :max, duration))
  end

  @impl VariableServiceBehaviour
  def handle_set_value(value, %ServiceState{} = state) when is_integer(value) do
    Playback.seek(value)
    state
  end

  @impl VariableServiceBehaviour
  def not_ready_reason(%ServiceState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
