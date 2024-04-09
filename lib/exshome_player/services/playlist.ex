defmodule ExshomePlayer.Services.Playlist do
  @moduledoc """
  Module responsible for a playlist.
  """

  alias Exshome.DataStream.Operation
  alias Exshome.Emitter
  alias Exshome.Service
  alias ExshomePlayer.Events.PlayerFileEndEvent
  alias ExshomePlayer.Schemas.Track
  alias ExshomePlayer.Services.Playback
  alias ExshomePlayer.Streams.TrackStream
  alias ExshomePlayer.Variables.Title

  use Exshome.Service.DependencyService,
    app: ExshomePlayer,
    name: "playlist"

  @spec play(id :: String.t()) :: :ok
  def play(id) when is_binary(id) do
    Service.call(__MODULE__, {:play, id})
  end

  @spec next() :: :ok
  def next, do: Service.call(__MODULE__, :next)

  @spec previous() :: :ok
  def previous, do: Service.call(__MODULE__, :previous)

  @impl ServiceBehaviour
  def init(%ServiceState{} = state) do
    :ok = Emitter.subscribe(PlayerFileEndEvent)
    :ok = Emitter.subscribe(TrackStream)
    :ok = Emitter.subscribe(Title)

    Track.refresh_tracklist()

    state
    |> update_value(fn _ -> Track.list() end)
    |> set_current_track(nil)
  end

  @impl DependencyServiceBehaviour
  def handle_service({Title, title}, %ServiceState{data: %Track{type: :file} = track} = state)
      when title != "" do
    Track.update!(track, %{title: title})
    state
  end

  def handle_service(_, %ServiceState{} = state), do: state

  @impl ServiceBehaviour
  def handle_call({:play, id}, _from, %ServiceState{} = state) when is_binary(id) do
    track =
      state.value
      |> Enum.find(fn %Track{id: track_id} -> track_id == id end)

    state =
      state
      |> set_current_track(track)
      |> load_track()

    {:reply, :ok, state}
  end

  def handle_call(:next, _from, %ServiceState{} = state) do
    state =
      state
      |> update_track(&move_to_next_track/2)
      |> load_track()

    {:reply, :ok, state}
  end

  def handle_call(:previous, _from, %ServiceState{} = state) do
    state =
      state
      |> update_track(&move_to_previous_track/2)
      |> load_track()

    {:reply, :ok, state}
  end

  @impl DependencyServiceBehaviour
  def handle_event({PlayerFileEndEvent, reason}, %ServiceState{} = state)
      when reason in ["eof", "error"] do
    state
    |> update_track(&move_to_next_track/2)
    |> load_track()
  end

  def handle_event({PlayerFileEndEvent, _}, %ServiceState{} = state), do: state

  @impl DependencyServiceBehaviour
  def handle_stream(
        {TrackStream, %Operation.Insert{data: %Track{} = track}},
        %ServiceState{value: value} = state
      ) do
    if Enum.any?(value, &(&1.id == track.id)) do
      state
    else
      update_value(state, fn value -> value ++ [track] end)
    end
  end

  def handle_stream(
        {TrackStream, %Operation.Update{data: %Track{} = track}},
        %ServiceState{} = state
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

  def handle_stream(
        {TrackStream, %Operation.Delete{data: %Track{id: id}}},
        %ServiceState{data: %Track{id: id} = track} = state
      ) do
    state
    |> update_value(fn value -> Enum.reject(value, &(&1.id == track.id)) end)
    |> set_current_track(nil)
    |> load_track()
  end

  def handle_stream(
        {TrackStream, %Operation.Delete{data: %Track{} = track}},
        %ServiceState{} = state
      ) do
    update_value(state, fn value -> Enum.reject(value, &(&1.id == track.id)) end)
  end

  @spec set_current_track(ServiceState.t(), Track.t() | nil) :: ServiceState.t()
  defp set_current_track(%ServiceState{} = state, current_track) do
    current_track_id = if current_track == nil, do: nil, else: current_track.id

    state
    |> update_data(fn _ -> current_track end)
    |> update_value(fn value ->
      Enum.map(value, &%Track{&1 | playing?: &1.id == current_track_id})
    end)
  end

  @spec load_track(ServiceState.t()) :: ServiceState.t()
  defp load_track(%ServiceState{data: nil} = state) do
    Playback.stop()
    state
  end

  defp load_track(%ServiceState{data: %Track{} = track} = state) do
    track
    |> Track.url()
    |> Playback.load_url()

    state
  end

  @spec update_track(
          state :: ServiceState.t(),
          (ServiceState.t(), [Track.t()] -> ServiceState.t())
        ) :: ServiceState.t()
  def update_track(%ServiceState{value: value} = state, change_fn) do
    change_fn.(state, value)
  end

  @spec move_to_next_track(ServiceState.t(), [Track.t()]) :: ServiceState.t()
  defp move_to_next_track(%ServiceState{data: nil} = state, _), do: state

  defp move_to_next_track(%ServiceState{data: %Track{id: id}} = state, value) do
    current_index = Enum.find_index(value, &(&1.id == id))
    next_track = Enum.at(value, current_index + 1)
    set_current_track(state, next_track)
  end

  @spec move_to_previous_track(ServiceState.t(), [Track.t()]) :: ServiceState.t()
  defp move_to_previous_track(%ServiceState{data: nil} = state, []), do: state

  defp move_to_previous_track(%ServiceState{data: nil} = state, [track | _]) do
    set_current_track(state, track)
  end

  defp move_to_previous_track(%ServiceState{data: %Track{id: id}} = state, value) do
    current_index = Enum.find_index(value, &(&1.id == id))
    next_track = Enum.at(value, current_index - 1)
    set_current_track(state, next_track)
  end
end
