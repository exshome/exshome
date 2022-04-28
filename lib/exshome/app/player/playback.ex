defmodule Exshome.App.Player.Playback do
  @moduledoc """
  Store playback state.
  """

  alias Exshome.App.Player.{MpvServer, MpvSocket, PlayerState}
  alias __MODULE__
  alias Exshome.App.Player.Playback.{MissingPlaylistItem, PlaylistItem}

  use Exshome.Dependency.GenServerDependency,
    name: "playback",
    dependencies: [{PlayerState.Path, :path}]

  defmodule Data do
    @moduledoc """
    Inner data format for playback.
    """

    defstruct playlist: []

    @type t() :: %__MODULE__{
            playlist: list(PlaylistItem.t())
          }
  end

  @type track() :: PlaylistItem.t() | MissingPlaylistItem

  defstruct current_track: MissingPlaylistItem,
            next_track: MissingPlaylistItem,
            previous_track: MissingPlaylistItem

  @type t() :: %__MODULE__{
          current_track: track(),
          next_track: track(),
          previous_track: track()
        }

  @spec playlist() :: list(PlaylistItem.t())
  def playlist do
    call(:playlist)
  end

  @spec load_file(url :: String.t()) :: MpvSocket.command_response()
  def load_file(url) when is_binary(url) do
    send_command(["playlist-clear"])
    send_command(["loadfile", url])
    play()
  end

  @spec next!() :: MpvSocket.command_response()
  def next! do
    %Playback{next_track: %PlaylistItem{url: url}} = Dependency.get_value(__MODULE__)
    load_file(url)
  end

  @spec previous!() :: MpvSocket.command_response()
  def previous! do
    %Playback{previous_track: %PlaylistItem{url: url}} = Dependency.get_value(__MODULE__)
    load_file(url)
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
    state
    |> update_data(fn _ -> %Data{playlist: compute_playlist()} end)
    |> update_value(%Playback{})
  end

  @impl GenServerDependency
  def handle_dependency_change(
        %DependencyState{
          data: %Data{playlist: playlist},
          deps: %{path: path},
          value: %Playback{current_track: previous_track} = value
        } = state
      ) do
    current_track =
      Enum.find_index(
        playlist,
        &(&1.url == path)
      )

    tracks =
      case current_track do
        nil -> []
        index -> Enum.slice(playlist, index, 2)
      end

    [current_track, next_track] =
      case tracks do
        [] -> [MissingPlaylistItem, MissingPlaylistItem]
        [track] -> [track, MissingPlaylistItem]
        data -> data
      end

    update_value(state, %Playback{
      value
      | previous_track: previous_track,
        current_track: current_track,
        next_track: next_track
    })
  end

  @impl GenServerDependency
  def handle_call(:playlist, _, %DependencyState{data: %Data{playlist: playlist}} = state) do
    {:reply, playlist, state}
  end

  @spec compute_playlist() :: list(PlaylistItem.t())
  defp compute_playlist do
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
end
