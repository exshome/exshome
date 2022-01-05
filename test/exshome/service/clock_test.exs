defmodule ExshomeTest.Service.ClockTest do
  use ExUnit.Case, async: true
  alias Exshome.Service.Clock
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.allow(self(), self())
    TestRegistry.start_service(Clock, %{refresh_interval: 1, precision: :microsecond})
  end

  test "clock works" do
    refute_received({Clock, _})
    initial_time = Clock.subscribe()
    assert_receive({Clock, current_time})
    assert current_time > initial_time
  end
end
