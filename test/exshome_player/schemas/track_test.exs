defmodule ExshomePlayerTest.Schemas.TrackTest do
  use Exshome.DataCase, async: true
  alias ExshomePlayer.Schemas.Track
  alias ExshomeTest.TestMpvServer

  setup do
    TestMpvServer.generate_random_tracks()
  end

  test "refresh_tracklist/0 collects tracks" do
    assert number_of_tracks() == 0
    Track.refresh_tracklist()
    assert number_of_tracks() > 0
  end

  test "refresh_tracklist/0 with manually deleted track" do
    Track.refresh_tracklist()
    initial_tracks = number_of_tracks()
    assert initial_tracks > 0

    Track.list() |> List.first() |> Track.url() |> File.rm!()
    assert number_of_tracks() == initial_tracks

    Track.refresh_tracklist()
    assert number_of_tracks() == initial_tracks - 1
  end

  def number_of_tracks, do: Track.list() |> length()
end
