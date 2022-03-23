defmodule ExshomeTest.App.Clock.LocalTimeTest do
  @moduledoc """
  Tests for LocalTime variable.
  """

  use ExUnit.Case, async: true
  alias Exshome.App.Clock
  alias Exshome.App.Clock.LocalTime
  alias Exshome.Dependency
  alias ExshomeTest.TestRegistry

  setup tags do
    TestRegistry.allow(self(), self())
    ExshomeTest.TestFileUtils.generate_test_folder(tags)
    ExshomeTest.TestDbUtils.start_test_db()
  end

  describe "LocalTime is not started" do
    test "returns NotReady" do
      assert Dependency.get_value(LocalTime) == Dependency.NotReady
    end
  end

  describe "LocalTime" do
    setup do
      TestRegistry.start_dependency(LocalTime)
    end

    test "returns NotReady without dependencies" do
      assert Dependency.get_value(LocalTime) == Dependency.NotReady
    end

    test "works with dependencies" do
      current_time = DateTime.utc_now()
      Dependency.broadcast_value(Clock.UtcTimeService, current_time)

      refute Dependency.get_value(LocalTime) == Dependency.NotReady
      assert Dependency.get_value(LocalTime) == current_time
    end
  end
end
