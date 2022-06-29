defmodule ExshomePlayer.Variables.Title do
  @moduledoc """
  Playback title.
  """

  alias ExshomePlayer.Services.PlayerState

  use Exshome.Variable,
    name: "player_title",
    dependencies: [{PlayerState, :player}]

  @impl GenServerDependency
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
end
