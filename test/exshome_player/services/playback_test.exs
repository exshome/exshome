defmodule ExshomePlayerTest.Services.PlaybackTest do
  use ExshomeTest.DataCase, async: true

  alias Exshome.Dependency
  alias ExshomePlayer.Services.{MpvSocket, Playback, PlayerState}
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
    Playback.load_url(file_location)
    assert %PlayerState{path: ^file_location, pause: false} = Dependency.get_value(PlayerState)
    assert [file_location] == playlist()
    Playback.pause()
    assert %PlayerState{pause: true} = Dependency.get_value(PlayerState)

    another_file = "another_file_#{unique_integer()}"
    Playback.load_url(another_file)
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

  test "client can stop track" do
    file_location = "test_file_#{unique_integer()}"
    Playback.load_url(file_location)
    assert %PlayerState{path: ^file_location, pause: false} = Dependency.get_value(PlayerState)
    assert [file_location] == playlist()
    Playback.stop()
    assert [] == playlist()
  end
end
