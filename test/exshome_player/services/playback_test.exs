defmodule ExshomePlayerTest.Services.PlaybackTest do
  use Exshome.DataCase, async: true

  alias Exshome.Dependency
  alias ExshomePlayer.Services.{MpvServer, MpvSocket, Playback, PlayerState}
  import ExshomeTest.Fixtures
  import ExshomeTest.TestMpvServer

  setup do
    server_fixture()
    ExshomeTest.TestRegistry.start_dependency(MpvSocket)
    ExshomeTest.TestRegistry.start_dependency(PlayerState)

    %{}
  end

  test "client can switch tracks" do
    file_location = "test_file_#{unique_integer()}"
    Playback.load_file(file_location)
    assert %PlayerState{path: ^file_location, pause: false} = Dependency.get_value(PlayerState)
    assert [file_location] == playlist()
    Playback.pause()
    assert %PlayerState{pause: true} = Dependency.get_value(PlayerState)

    another_file = "another_file_#{unique_integer()}"
    Playback.load_file(another_file)
    assert %PlayerState{path: ^another_file, pause: false} = Dependency.get_value(PlayerState)
    assert [another_file] == playlist()
  end

  test "client can set volume" do
    volume_level = unique_integer()
    Playback.set_volume(volume_level)
    assert %PlayerState{volume: ^volume_level} = Dependency.get_value(PlayerState)
  end

  test "client can seek a file" do
    time_pos = unique_integer()
    Playback.seek(time_pos)
    assert %PlayerState{time_pos: ^time_pos} = Dependency.get_value(PlayerState)
  end

  describe "empty tracklist/0" do
    setup do
      ExshomeTest.TestRegistry.start_dependency(Playback)
    end

    test "shows an empty tracklist" do
      assert [] = Playback.tracklist()
    end
  end

  describe "tracklist/0 with tracks" do
    setup do
      generate_random_tracks()
      ExshomeTest.TestRegistry.start_dependency(Playback)
    end

    test "shows non-empty tracklist" do
      assert Enum.count(Playback.tracklist()) > 0
    end
  end

  @spec generate_random_tracks() :: list(String.t())
  defp generate_random_tracks do
    amount = Enum.random(1..10)

    for _ <- 1..amount do
      file_name = "track_#{unique_integer()}.mp3"

      :ok =
        MpvServer.music_folder()
        |> Path.join(file_name)
        |> File.touch!()

      file_name
    end
  end
end
