defmodule ExshomePlayer.Services.Playlist do
  @moduledoc """
  Module responsible for a playlist.
  """

  alias ExshomePlayer.Events.PlayerFileEndEvent
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Streams.TrackStream
  alias ExshomePlayer.Variables.Title

  use Exshome.Dependency.GenServerDependency,
    name: "playlist",
    subscribe: [
      dependencies: [{Title, :title}],
      events: [PlayerFileEndEvent],
      streams: [TrackStream]
    ]

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

    state
    |> update_value(fn _ -> Track.list() end)
    |> set_current_track(nil)
  end

  @impl Subscription
  def on_dependency_change(
        %DependencyState{
          data: %Track{type: :file} = track,
          deps: %{title: title}
        } = state
      )
      when title != "" do
    Track.update!(track, %{title: title})
    state
  end

  def on_dependency_change(%DependencyState{} = state), do: state

  @impl GenServerDependency
  def handle_call({:play, id}, _from, %DependencyState{} = state) when is_binary(id) do
    track = Enum.find(state.value, fn %Track{id: track_id} -> track_id == id end)

    state =
      state
      |> set_current_track(track)
      |> load_track()

    {:reply, :ok, state}
  end

  def handle_call(:next, _from, %DependencyState{} = state) do
    state =
      state
      |> move_to_next_track()
      |> load_track()

    {:reply, :ok, state}
  end

  def handle_call(:previous, _from, %DependencyState{} = state) do
    state =
      state
      |> move_to_previous_track()
      |> load_track()

    {:reply, :ok, state}
  end

  @impl Subscription
  def on_event(%DependencyState{} = state, {PlayerFileEndEvent, reason})
      when reason in ["eof", "error"] do
    state
    |> move_to_next_track()
    |> load_track()
  end

  def on_event(%DependencyState{} = state, {PlayerFileEndEvent, _}), do: state

  @impl Subscription
  def on_stream(
        %DependencyState{} = state,
        {TrackStream, %Operation.Insert{data: %Track{} = track}}
      ) do
    if Enum.any?(state.value, &(&1.id == track.id)) do
      state
    else
      update_value(state, fn value -> value ++ [track] end)
    end
  end

  def on_stream(
        %DependencyState{} = state,
        {TrackStream, %Operation.Update{data: %Track{} = track}}
      ) do
    replace_updated_track = fn %Track{} = current ->
      if current.id == track.id do
        %Track{track | playing?: current.playing?}
      else
        current
      end
    end

    update_value(state, &Enum.map(&1, replace_updated_track))
  end

  def on_stream(
        %DependencyState{data: %Track{id: id} = track} = state,
        {TrackStream, %Operation.Delete{data: %Track{id: id}}}
      ) do
    state
    |> update_value(fn value -> Enum.reject(value, &(&1.id == track.id)) end)
    |> set_current_track(nil)
    |> load_track()
  end

  def on_stream(
        %DependencyState{} = state,
        {TrackStream, %Operation.Delete{data: %Track{} = track}}
      ) do
    update_value(state, fn value -> Enum.reject(value, &(&1.id == track.id)) end)
  end

  @spec set_current_track(DependencyState.t(), Track.t() | nil) :: DependencyState.t()
  defp set_current_track(%DependencyState{} = state, current_track) do
    current_track_id = if current_track == nil, do: nil, else: current_track.id

    state
    |> update_data(fn _ -> current_track end)
    |> update_value(fn value ->
      Enum.map(value, &%Track{&1 | playing?: &1.id == current_track_id})
    end)
  end

  @spec load_track(DependencyState.t()) :: DependencyState.t()
  defp load_track(%DependencyState{data: nil} = state) do
    Playback.stop()
    state
  end

  defp load_track(%DependencyState{data: %Track{} = track} = state) do
    track
    |> Track.url()
    |> Playback.load_url()

    state
  end

  @spec move_to_next_track(DependencyState.t()) :: DependencyState.t()
  defp move_to_next_track(%DependencyState{data: nil} = state), do: state

  defp move_to_next_track(%DependencyState{data: %Track{id: id}} = state) do
    current_index = Enum.find_index(state.value, &(&1.id == id))
    next_track = Enum.at(state.value, current_index + 1)
    set_current_track(state, next_track)
  end

  @spec move_to_previous_track(DependencyState.t()) :: DependencyState.t()
  defp move_to_previous_track(%DependencyState{data: nil, value: []} = state), do: state

  defp move_to_previous_track(%DependencyState{data: nil, value: [track | _]} = state) do
    set_current_track(state, track)
  end

  defp move_to_previous_track(%DependencyState{data: %Track{id: id}} = state) do
    current_index = Enum.find_index(state.value, &(&1.id == id))
    next_track = Enum.at(state.value, current_index - 1)
    set_current_track(state, next_track)
  end
end
