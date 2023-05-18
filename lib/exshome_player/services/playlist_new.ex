defmodule ExshomePlayer.Services.PlaylistNew do
  alias ExshomePlayer.Events.{PlayerFileEnd, TrackEvent}
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Variables.Title

  use Exshome.DataStream.GenServerDataStream,
    name: "playlist_new",
    subscribe: [
      dependencies: [{Title, :title}],
      events: [PlayerFileEnd, TrackEvent]
    ]

  defstruct [:current_id, tracks: []]

  defmodule Data do
    @moduledoc """
    Inner data format for playback.
    """

    defstruct next: [], previous: []

    @type t() :: %__MODULE__{
            previous: list(Track.t()),
            next: list(Track.t())
          }
  end

  @impl GenServerDependency
  def on_init(%DependencyState{} = state) do
    Track.refresh_tracklist()
    update_playlist(state, fn _ -> %Data{previous: Enum.reverse(Track.list())} end)
  end

  @type t() :: %__MODULE__{
          current_id: String.t() | nil,
          tracks: list(Track.t())
        }

  @spec update_playlist(DependencyState.t(), (Data.t() -> Data.t())) :: DependencyState.t()
  defp update_playlist(%DependencyState{} = state, update_fn) do
    state
    |> update_data(update_fn)
    |> refresh_playlist()
  end

  @spec refresh_playlist(DependencyState.t()) :: DependencyState.t()
  defp refresh_playlist(%DependencyState{data: %Data{} = data} = state) do
    update_value(
      state,
      fn _ ->
        %__MODULE__{
          current_id: nil,
          tracks: Enum.reverse(data.previous) ++ data.next
        }
      end
    )
  end

  def tracklist, do: []

  def previous, do: :ok

  def next, do: :ok

  def play(_), do: :ok
end
