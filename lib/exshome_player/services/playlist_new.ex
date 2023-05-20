defmodule ExshomePlayer.Services.PlaylistNew do
  @moduledoc """
  Module responsible for a playlist features.
  """

  alias ExshomePlayer.Events.{PlayerFileEnd, TrackEvent}
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Variables.Title

  use Exshome.DataStream.GenServerDataStream,
    name: "playlist_new",
    subscribe: [
      dependencies: [{Title, :title}],
      events: [PlayerFileEnd, TrackEvent]
    ]

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
    update_playlist(state, fn _ -> %Data{previous: Enum.reverse(Track.list())} end)
  end

  @impl Subscription
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

  @impl Subscription
  def handle_event(%PlayerFileEnd{reason: reason}, %DependencyState{} = state)
      when reason in ["eof", "error"] do
    state
    |> update_playlist(&move_to_next_track/1)
    |> load_track()
  end

  def handle_event(%PlayerFileEnd{}, %DependencyState{} = state), do: state

  def handle_event(%TrackEvent{track: track, action: :created}, %DependencyState{} = state) do
    if Enum.any?(state.value, &(&1.id == track.id)) do
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

  @impl GenServerDependency
  def handle_call({:play, id}, _from, %DependencyState{value: tracks} = state)
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
        combine_playlist(
          Enum.reverse(data.previous),
          data.next
        )
      end
    )
  end

  @spec combine_playlist([Track.t()], [Track.t()]) :: [Track.t()]
  defp combine_playlist(previous, []), do: Enum.map(previous, &set_playing(&1, false))

  defp combine_playlist(previous, [%Track{} = current_track | next]) do
    Enum.map(previous, &set_playing(&1, false)) ++
      [set_playing(current_track, true)] ++
      Enum.map(next, &set_playing(&1, false))
  end

  @spec set_playing(Track.t(), boolean()) :: Track.t()
  defp set_playing(%Track{} = track, playing?), do: %Track{track | playing?: playing?}

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
