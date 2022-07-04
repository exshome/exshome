defmodule ExshomePlayerTest.VariablesTest do
  use Exshome.DataCase, async: true

  import ExshomeTest.Fixtures

  alias Exshome.Dependency
  alias ExshomePlayer.Services.PlayerState
  alias ExshomePlayer.Variables
  alias ExshomeTest.TestRegistry

  describe "Variables.Duration" do
    setup do
      TestRegistry.start_dependency(Variables.Duration)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(Variables.Duration) == 0
    end

    test "non-empty value" do
      duration = unique_integer()
      Dependency.broadcast_value(PlayerState, %PlayerState{duration: duration})
      assert Dependency.get_value(Variables.Duration) == duration
    end
  end

  describe "Variables.Pause" do
    setup do
      TestRegistry.start_dependency(Variables.Pause)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(Variables.Pause)
    end

    test "non-empty value, no track is playing" do
      Dependency.broadcast_value(PlayerState, %PlayerState{pause: false})
      assert Dependency.get_value(Variables.Pause)
    end

    test "non-empty value, some track is playing" do
      Dependency.broadcast_value(PlayerState, %PlayerState{pause: false, path: "some_path"})
      refute Dependency.get_value(Variables.Pause)
    end
  end

  describe "Variables.Position" do
    setup do
      TestRegistry.start_dependency(Variables.Position)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(Variables.Position) == 0
    end

    test "non-empty value" do
      position = unique_integer()
      Dependency.broadcast_value(PlayerState, %PlayerState{time_pos: position})
      assert Dependency.get_value(Variables.Position) == position
    end
  end

  describe "Variables.Title" do
    setup do
      TestRegistry.start_dependency(Variables.Title)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(Variables.Title) == ""
    end

    test "unknown title" do
      broadcast_metadata(%{})
      assert Dependency.get_value(Variables.Title) == "Unknown title"
    end

    test "streaming title" do
      title = "some_title#{unique_integer()}"
      broadcast_metadata(%{"icy-title" => title})
      assert Dependency.get_value(Variables.Title) == title
    end

    test "artist and title" do
      title = "some_title#{unique_integer()}"
      artist = "some_artist#{unique_integer()}"
      broadcast_metadata(%{"title" => title, "artist" => artist})
      assert Dependency.get_value(Variables.Title) == "#{artist} - #{title}"
    end

    test "only title" do
      title = "some_title#{unique_integer()}"
      broadcast_metadata(%{"title" => title})
      assert Dependency.get_value(Variables.Title) == title
    end

    def broadcast_metadata(%{} = metadata) do
      Dependency.broadcast_value(PlayerState, %PlayerState{metadata: metadata})
    end
  end

  describe "Variables.Volume" do
    setup do
      TestRegistry.start_dependency(Variables.Volume)
    end

    test "check default value" do
      Dependency.broadcast_value(PlayerState, %PlayerState{})
      assert Dependency.get_value(Variables.Volume) == 0
    end

    test "non-empty value" do
      volume = unique_integer()
      Dependency.broadcast_value(PlayerState, %PlayerState{volume: volume})
      assert Dependency.get_value(Variables.Volume) == volume
    end
  end
end
