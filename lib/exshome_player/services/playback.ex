defmodule ExshomePlayer.Services.Playback do
  @moduledoc """
  Store playback state.
  """

  alias ExshomePlayer.Events.PlayerFileEnd
  alias ExshomePlayer.Services.{MpvServer, MpvSocket}
  alias ExshomePlayer.Services.Playback.{MissingPlaylistItem, PlaylistItem}

  use Exshome.Dependency.GenServerDependency,
    events: [PlayerFileEnd],
    name: "playback"

  defmodule Data do
    @moduledoc """
    Inner data format for playback.
    """

    defstruct current: MissingPlaylistItem, next: [], previous: []

    @type t() :: %__MODULE__{
            previous: list(PlaylistItem.t()),
            current: PlaylistItem.t() | MissingPlaylistItem,
            next: list(PlaylistItem.t())
          }
  end

  @spec next() :: :ok
  def next, do: call(:next)

  @spec previous() :: :ok
  def previous, do: call(:previous)

  @spec playlist() :: list(PlaylistItem.t())
  def playlist, do: call(:playlist)

  @spec load_file(url :: String.t()) :: MpvSocket.command_response()
  def load_file(url) when is_binary(url) do
    send_command(["playlist-clear"])
    send_command(["loadfile", url])
    play()
  end

  @spec play() :: MpvSocket.command_response()
  def play do
    set_property("pause", false)
  end

  @spec pause() :: MpvSocket.command_response()
  def pause do
    set_property("pause", true)
  end

  @spec set_volume(level :: integer()) :: MpvSocket.command_response()
  def set_volume(level) when is_number(level) do
    set_property("volume", level)
  end

  @spec seek(duration :: integer()) :: MpvSocket.command_response()
  def seek(time_pos) when is_number(time_pos) do
    send_command(["seek", time_pos, "absolute"])
  end

  @spec set_property(property :: String.t(), value :: term()) :: MpvSocket.command_response()
  def set_property(property, value) do
    send_command(["set_property", property, value])
  end

  defdelegate send_command(payload), to: MpvSocket

  @impl GenServerDependency
  def on_init(%DependencyState{} = state) do
    {current, next} =
      List.pop_at(
        load_playlist(),
        0,
        MissingPlaylistItem
      )

    state
    |> update_data(fn _ -> %Data{current: current, next: next} end)
    |> update_value(:ready)
  end

  @impl GenServerDependency
  def handle_event(PlayerFileEnd, %DependencyState{} = state) do
    update_value(state, &load_next_track/1)
  end

  @impl GenServerDependency
  def handle_call(:playlist, _, %DependencyState{data: %Data{} = data} = state) do
    {:reply, compute_playlist(data), state}
  end

  def handle_call(:previous, _, %DependencyState{} = state) do
    {:reply, :ok, update_data(state, &load_previous_track/1)}
  end

  def handle_call(:next, _, %DependencyState{} = state) do
    {:reply, :ok, update_data(state, &load_next_track/1)}
  end

  @spec load_playlist() :: list(PlaylistItem.t())
  defp load_playlist do
    music_folder = MpvServer.music_folder()

    music_folder
    |> File.ls!()
    |> Enum.map(
      &%PlaylistItem{
        name: &1,
        url: Path.join(music_folder, &1)
      }
    )
  end

  @spec load_next_track(Data.t()) :: Data.t()
  defp load_next_track(%Data{next: []} = data) do
    {current, next} =
      data
      |> compute_playlist()
      |> List.pop_at(0, MissingPlaylistItem)

    %Data{data | current: current, next: next, previous: []}
  end

  defp load_next_track(%Data{current: previous, next: [current | next]} = data) do
    load_file(current.url)

    %Data{
      data
      | previous: [previous | data.previous],
        next: next,
        current: current
    }
  end

  @spec load_previous_track(Data.t()) :: Data.t()
  defp load_previous_track(%Data{previous: []} = data), do: data

  defp load_previous_track(%Data{previous: [current | previous], current: next} = data) do
    load_file(current.url)

    %Data{
      data
      | previous: previous,
        current: current,
        next: [next | data.next]
    }
  end

  @spec compute_playlist(Data.t()) :: list(PlaylistItem.t())
  def compute_playlist(%Data{} = data) do
    current = if data.current == MissingPlaylistItem, do: [], else: [data.current]
    Enum.reverse(data.previous) ++ current ++ data.next
  end
end
