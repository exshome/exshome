defmodule ExshomePlayer.Variables.Title do
  @moduledoc """
  Playback title.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable.GenServerVariable,
    app: ExshomePlayer,
    name: "player_title",
    subscribe: [
      dependencies: [{PlayerState, :player}]
    ],
    variable: [
      group: "player",
      readonly?: true,
      type: Exshome.Datatype.String
    ]

  @impl Subscription
  def on_dependency_change(%DependencyState{deps: %{player: %PlayerState{} = player}} = state) do
    title = extract_title(player.metadata)
    update_value(state, fn _ -> title end)
  end

  @spec extract_title(map() | nil) :: String.t()
  defp extract_title(nil), do: ""
  defp extract_title(%{"icy-title" => title}), do: title
  defp extract_title(%{"artist" => artist, "title" => title}), do: "#{artist} - #{title}"
  defp extract_title(%{"title" => title}), do: title
  defp extract_title(_), do: "Unknown title"

  @impl GenServerVariable
  def not_ready_reason(%DependencyState{deps: %{player: %PlayerState{path: nil}}}) do
    "No track is playing"
  end

  def not_ready_reason(_), do: nil
end
