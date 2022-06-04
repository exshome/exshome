defmodule ExshomePlayer.Services.Playlist do
  @moduledoc """
  Module responsible for a playlist.
  """

  alias ExshomePlayer.Events.{PlayerFileEnd, TrackEvent}
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playback

  use Exshome.Dependency.GenServerDependency,
    events: [PlayerFileEnd, TrackEvent],
    name: "playlist"

  defstruct [:current_id, tracks: []]

  @type t() :: %__MODULE__{
          current_id: String.t() | nil,
          tracks: list(Track.t())
        }

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

  @spec play(id :: String.t()) :: :ok
  def play(id) when is_binary(id) do
    call({:play, id})
  end

  @impl GenServerDependency
  def on_init(%DependencyState{} = state),
    do: update_playlist(state, fn _ -> %Data{previous: Track.list()} end)

  @impl GenServerDependency
  def handle_call(
        {:play, id},
        _from,
        %DependencyState{value: %__MODULE__{tracks: tracks}} = state
      )
      when is_binary(id) do
    {previous, next} = Enum.split_while(tracks, &(&1.id != id))

    state =
      state
      |> update_playlist(fn _ ->
        %Data{
          previous: Enum.reverse(previous),
          next: next
        }
      end)
      |> load_track()

    {:reply, :ok, state}
  end

  @impl GenServerDependency
  def handle_event(PlayerFileEnd, %DependencyState{} = state) do
    state
    |> update_data(&load_next_track/1)
    |> load_track()
  end

  def handle_event(%TrackEvent{action: :created, track: track}, %DependencyState{} = state) do
    update_playlist(state, fn %Data{} = data ->
      %Data{data | previous: data.previous ++ [track]}
    end)
  end

  def handle_event(
        %TrackEvent{action: :deleted, track: %Track{id: id}},
        %DependencyState{data: %Data{next: [%Track{id: id} | next]}} = state
      ) do
    state
    |> update_playlist(fn %Data{} = data ->
      %Data{previous: data.previous ++ Enum.reverse(next), next: []}
    end)
    |> load_track()
  end

  def handle_event(
        %TrackEvent{action: :deleted, track: %Track{id: id}},
        %DependencyState{} = state
      ) do
    update_playlist(state, fn %Data{} = data ->
      %Data{
        previous: Enum.reject(data.previous, &(&1.id == id)),
        next: Enum.reject(data.next, &(&1.id == id))
      }
    end)
  end

  @spec update_playlist(DependencyState.t(), (Data.t() -> Data.t())) :: DependencyState.t()
  defp update_playlist(%DependencyState{} = state, update_fn) do
    state
    |> update_data(update_fn)
    |> compute_playlist()
  end

  @spec compute_playlist(DependencyState.t()) :: DependencyState.t()
  defp compute_playlist(%DependencyState{data: %Data{next: [%Track{id: id} | _]} = data} = state) do
    update_value(
      state,
      %__MODULE__{
        current_id: id,
        tracks: Enum.reverse(data.previous) ++ data.next
      }
    )
  end

  defp compute_playlist(%DependencyState{data: %Data{} = data} = state) do
    update_value(
      state,
      %__MODULE__{
        current_id: nil,
        tracks: Enum.reverse(data.previous) ++ data.next
      }
    )
  end

  @spec load_track(DependencyState.t()) :: DependencyState.t()
  defp load_track(%DependencyState{data: %Data{next: []}} = state) do
    Playback.stop()
    state
  end

  defp load_track(%DependencyState{data: %Data{next: [track | _]}} = state) do
    track
    |> Track.url()
    |> Playback.load_url()

    state
  end

  @spec load_next_track(Data.t()) :: Data.t()
  defp load_next_track(%Data{next: []} = data), do: data

  defp load_next_track(%Data{previous: previous, next: [current | next]}) do
    %Data{previous: [current | previous], next: next}
  end
end
