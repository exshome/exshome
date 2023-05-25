defmodule ExshomePlayer.Services.Playlist do
  @moduledoc """
  Module responsible for a playlist.
  """

  alias Exshome.DataStream
  alias ExshomePlayer.Events.PlayerFileEnd
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Streams.{PlaylistStream, TrackStream}
  alias ExshomePlayer.Variables.Title

  use Exshome.Dependency.GenServerDependency,
    name: "playlist",
    subscribe: [
      dependencies: [{Title, :title}],
      events: [PlayerFileEnd],
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
  def on_event(%DependencyState{} = state, %PlayerFileEnd{reason: reason})
      when reason in ["eof", "error"] do
    state
    |> move_to_next_track()
    |> load_track()
  end

  def on_event(%DependencyState{} = state, %PlayerFileEnd{}), do: state

  @impl Subscription
  def on_stream(%DependencyState{} = state, TrackStream, %Operation.ReplaceAll{data: data}) do
    state
    |> update_value(fn _ -> data end)
    |> set_current_track(state.data)
  end

  def on_stream(%DependencyState{} = state, TrackStream, %Operation.Insert{data: %Track{} = track}) do
    if Enum.any?(state.value, &(&1.id == track.id)) do
      state
    else
      :ok = broadcast_changes([%Operation.Insert{data: track, at: -1}])
      update_value(state, fn value -> value ++ [track] end)
    end
  end

  def on_stream(%DependencyState{} = state, TrackStream, %Operation.Update{data: %Track{} = track}) do
    track_position = Enum.find_index(state.value, &(&1.id == track.id))
    %Track{} = local_track = Enum.at(state.value, track_position)
    updated_track = %Track{track | playing?: local_track.playing?}
    broadcast_changes([%Operation.Update{data: updated_track, at: track_position}])

    replace_updated_track = fn %Track{} = current ->
      if current.id == updated_track.id do
        updated_track
      else
        current
      end
    end

    update_value(state, &Enum.map(&1, replace_updated_track))
  end

  def on_stream(
        %DependencyState{data: %Track{id: id} = track} = state,
        TrackStream,
        %Operation.Delete{data: %Track{id: id}}
      ) do
    :ok = broadcast_changes([%Operation.Delete{data: track}])

    state
    |> update_value(fn value -> Enum.reject(value, &(&1.id == track.id)) end)
    |> set_current_track(nil)
    |> load_track()
  end

  def on_stream(%DependencyState{} = state, TrackStream, %Operation.Delete{data: %Track{} = track}) do
    :ok = broadcast_changes([%Operation.Delete{data: track}])

    update_value(state, fn value -> Enum.reject(value, &(&1.id == track.id)) end)
  end

  @spec set_current_track(DependencyState.t(), Track.t() | nil) :: DependencyState.t()
  defp set_current_track(%DependencyState{} = state, current_track) do
    current_track_id = if current_track == nil, do: nil, else: current_track.id

    {changes, reverse_value} =
      for {%Track{} = track, index} <- Enum.with_index(state.value), reduce: {[], []} do
        {changes, value} ->
          cond do
            track.playing? && current_track_id != track.id ->
              track = %Track{track | playing?: false}
              {[%Operation.Update{data: track, at: index} | changes], [track | value]}

            !track.playing? && current_track_id == track.id ->
              track = %Track{track | playing?: true}
              {[%Operation.Update{data: track, at: index} | changes], [track | value]}

            true ->
              {changes, [track | value]}
          end
      end

    :ok = broadcast_changes(changes)

    state
    |> update_data(fn _ -> current_track end)
    |> update_value(fn _ -> Enum.reverse(reverse_value) end)
  end

  @spec broadcast_changes([Operation.single_operation()]) :: :ok
  defp broadcast_changes([]), do: :ok
  defp broadcast_changes([change]), do: DataStream.broadcast(PlaylistStream, change)

  defp broadcast_changes(changes),
    do: DataStream.broadcast(PlaylistStream, %Operation.Batch{operations: changes})

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
