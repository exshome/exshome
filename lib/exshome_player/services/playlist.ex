defmodule ExshomePlayer.Services.Playlist do
  @moduledoc """
  Module responsible for a playlist.
  """

  alias ExshomePlayer.Events.{PlayerFileEnd, TrackEvent}
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Variables.Title

  use Exshome.Dependency.GenServerDependency,
    dependencies: [{Title, :title}],
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

  @spec next() :: :ok
  def next, do: call(:next)

  @spec previous() :: :ok
  def previous, do: call(:previous)

  @impl GenServerDependency
  def on_init(%DependencyState{} = state) do
    Track.refresh_tracklist()
    update_playlist(state, fn _ -> %Data{previous: Track.list()} end)
  end

  @impl GenServerDependency
  def handle_dependency_change(
        %DependencyState{
          data: %Data{next: [%Track{type: :file} = track | _]},
          deps: %{title: title}
        } = state
      )
      when title != "" do
    Track.update!(track, %{title: title})
    state
  end

  def handle_dependency_change(%DependencyState{} = state), do: state

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

  def handle_call(:next, _from, %DependencyState{} = state) do
    state =
      state
      |> update_playlist(&move_to_next_track/1)
      |> load_track()

    {:reply, :ok, state}
  end

  def handle_call(:previous, _from, %DependencyState{} = state) do
    state =
      state
      |> update_playlist(&move_to_previous_track/1)
      |> load_track()

    {:reply, :ok, state}
  end

  @impl GenServerDependency
  def handle_event(%PlayerFileEnd{reason: "eof"}, %DependencyState{} = state) do
    state
    |> update_playlist(&move_to_next_track/1)
    |> load_track()
  end

  def handle_event(%PlayerFileEnd{}, %DependencyState{} = state), do: state

  def handle_event(%TrackEvent{action: :created, track: track}, %DependencyState{} = state) do
    if Enum.any?(state.value.tracks, &(&1.id == track.id)) do
      state
    else
      update_playlist(state, fn %Data{} = data ->
        %Data{data | previous: data.previous ++ [track]}
      end)
    end
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

  def handle_event(
        %TrackEvent{action: :updated, track: %Track{} = track},
        %DependencyState{} = state
      ) do
    update_fn = fn %Track{} = current ->
      if current.id == track.id do
        track
      else
        current
      end
    end

    update_playlist(
      state,
      fn %Data{} = data ->
        %Data{
          previous: Enum.map(data.previous, update_fn),
          next: Enum.map(data.next, update_fn)
        }
      end
    )
  end

  @spec update_playlist(DependencyState.t(), (Data.t() -> Data.t())) :: DependencyState.t()
  defp update_playlist(%DependencyState{} = state, update_fn) do
    state
    |> update_data(update_fn)
    |> refresh_playlist()
  end

  @spec refresh_playlist(DependencyState.t()) :: DependencyState.t()
  defp refresh_playlist(%DependencyState{data: %Data{next: [%Track{id: id} | _]} = data} = state) do
    update_value(
      state,
      %__MODULE__{
        current_id: id,
        tracks: Enum.reverse(data.previous) ++ data.next
      }
    )
  end

  defp refresh_playlist(%DependencyState{data: %Data{} = data} = state) do
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

  @spec move_to_next_track(Data.t()) :: Data.t()
  defp move_to_next_track(%Data{next: []} = data), do: data

  defp move_to_next_track(%Data{previous: previous, next: [current | next]}) do
    %Data{previous: [current | previous], next: next}
  end

  @spec move_to_previous_track(Data.t()) :: Data.t()
  defp move_to_previous_track(%Data{previous: []} = data), do: data

  defp move_to_previous_track(%Data{previous: [current | previous], next: next}) do
    %Data{previous: previous, next: [current | next]}
  end
end
