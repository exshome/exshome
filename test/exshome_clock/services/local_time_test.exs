defmodule ExshomeClockTest.Services.LocalTimeTest do
  @moduledoc """
  Tests for LocalTime dependency.
  """

  use ExshomeTest.DataCase, async: true

  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias Exshome.Settings
  alias ExshomeClock.Services.{LocalTime, UtcTime}
  alias ExshomeClock.Settings.ClockSettings
  alias ExshomeTest.TestRegistry

  describe "LocalTime is not started" do
    test "returns NotReady" do
      assert Dependency.get_value(LocalTime) == NotReady
    end
  end

  describe "LocalTime" do
    setup do
      TestRegistry.start_dependency(LocalTime)
    end

    test "returns NotReady without dependencies" do
      assert Dependency.get_value(LocalTime) == NotReady
    end

    test "works with dependencies" do
      current_time = DateTime.utc_now()
      Emitter.broadcast(UtcTime, current_time)

      refute Dependency.get_value(LocalTime) == NotReady
      assert Dependency.get_value(LocalTime) == current_time
    end

    test "syncs after timezone is updated" do
      current_time = DateTime.utc_now()
      Emitter.broadcast(UtcTime, current_time)

      assert Dependency.get_value(LocalTime).time_zone == current_time.time_zone

      random_timezone =
        Settings.allowed_values(ClockSettings).timezone
        |> Enum.random()

      Settings.save_settings(%ClockSettings{timezone: random_timezone})

      assert Dependency.get_value(LocalTime).time_zone == random_timezone
    end
  end
end
