defmodule ExshomePlayerTest.PlayerStateVariablesTest do
  use Exshome.DataCase, async: true

  import ExshomeTest.Fixtures

  alias Exshome.Dependency
  alias ExshomePlayer.PlayerState
  alias ExshomeTest.TestRegistry

  describe "PlayerState.Duration" do
    setup do
      TestRegistry.start_dependency(PlayerState.Duration)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(PlayerState.Duration) == 0
    end

    test "non-empty value" do
      duration = unique_integer()
      Dependency.broadcast_value(PlayerState, %PlayerState{duration: duration})
      assert Dependency.get_value(PlayerState.Duration) == duration
    end
  end

  describe "PlayerState.Path" do
    setup do
      TestRegistry.start_dependency(PlayerState.Path)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(PlayerState.Path) == ""
    end

    test "non-empty value" do
      path = "some path #{unique_integer()}"
      Dependency.broadcast_value(PlayerState, %PlayerState{path: path})
      assert Dependency.get_value(PlayerState.Path) == path
    end
  end

  describe "PlayerState.Pause" do
    setup do
      TestRegistry.start_dependency(PlayerState.Pause)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(PlayerState.Pause)
    end

    test "non-empty value, no track is playing" do
      Dependency.broadcast_value(PlayerState, %PlayerState{pause: false})
      assert Dependency.get_value(PlayerState.Pause)
    end

    test "non-empty value, some track is playing" do
      Dependency.broadcast_value(PlayerState, %PlayerState{pause: false, path: "some_path"})
      refute Dependency.get_value(PlayerState.Pause)
    end
  end

  describe "PlayerState.Position" do
    setup do
      TestRegistry.start_dependency(PlayerState.Position)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(PlayerState.Position) == 0
    end

    test "non-empty value" do
      position = unique_integer()
      Dependency.broadcast_value(PlayerState, %PlayerState{time_pos: position})
      assert Dependency.get_value(PlayerState.Position) == position
    end
  end

  describe "PlayerState.Title" do
    setup do
      TestRegistry.start_dependency(PlayerState.Title)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(PlayerState.Title) == ""
    end

    test "unknown title" do
      broadcast_metadata(%{})
      assert Dependency.get_value(PlayerState.Title) == "Unknown title"
    end

    test "streaming title" do
      title = "some_title#{unique_integer()}"
      broadcast_metadata(%{"icy-title" => title})
      assert Dependency.get_value(PlayerState.Title) == title
    end

    test "artist and title" do
      title = "some_title#{unique_integer()}"
      artist = "some_artist#{unique_integer()}"
      broadcast_metadata(%{"title" => title, "artist" => artist})
      assert Dependency.get_value(PlayerState.Title) == "#{artist} - #{title}"
    end

    test "only title" do
      title = "some_title#{unique_integer()}"
      broadcast_metadata(%{"title" => title})
      assert Dependency.get_value(PlayerState.Title) == title
    end

    def broadcast_metadata(%{} = metadata) do
      Dependency.broadcast_value(PlayerState, %PlayerState{metadata: metadata})
    end
  end

  describe "PlayerState.Volume" do
    setup do
      TestRegistry.start_dependency(PlayerState.Volume)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(PlayerState.Volume) == 0
    end

    test "non-empty value" do
      volume = unique_integer()
      Dependency.broadcast_value(PlayerState, %PlayerState{volume: volume})
      assert Dependency.get_value(PlayerState.Volume) == volume
    end
  end
end
