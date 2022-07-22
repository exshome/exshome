defmodule ExshomePlayer.Variables.Title do
  @moduledoc """
  Playback title.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    name: "player_title",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ],
    variable: [
      group: "player",
      readonly: true,
      type: Exshome.DataType.String
    ]

  @impl Subscription
  def handle_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    title = extract_title(player.metadata)
    update_value(state, title)
  end

  @spec extract_title(map() | nil) :: String.t()
  defp extract_title(nil), do: ""
  defp extract_title(%{"icy-title" => title}), do: title
  defp extract_title(%{"artist" => artist, "title" => title}), do: "#{artist} - #{title}"
  defp extract_title(%{"title" => title}), do: title
  defp extract_title(_), do: "Unknown title"

  @impl Variable
  def not_ready_reason(%DependencyState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
