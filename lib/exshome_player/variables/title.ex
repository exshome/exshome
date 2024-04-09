defmodule ExshomePlayer.Variables.Title do
  @moduledoc """
  Playback title.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Service.VariableService,
    app: ExshomePlayer,
    name: "player_title",
    dependencies: [player: PlayerState],
    variable: [
      group: "player",
      readonly?: true,
      type: Exshome.Datatype.String
    ]

  @impl DependencyServiceBehaviour
  def handle_dependency_change(%ServiceState{deps: %{player: %PlayerState{} = player}} = state) do
    title = extract_title(player.metadata)
    update_value(state, fn _ -> title end)
  end

  @spec extract_title(map() | nil) :: String.t()
  defp extract_title(nil), do: ""
  defp extract_title(%{"icy-title" => title}), do: title
  defp extract_title(%{"artist" => artist, "title" => title}), do: "#{artist} - #{title}"
  defp extract_title(%{"title" => title}), do: title
  defp extract_title(_), do: "Unknown title"

  @impl VariableServiceBehaviour
  def not_ready_reason(%ServiceState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
