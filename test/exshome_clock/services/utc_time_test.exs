defmodule ExshomeClockTest.Services.UtcTimeTest do
  use ExshomeTest.DataCase, async: true
  import ExshomeTest.TestHelpers
  alias Exshome.Dependency
  alias ExshomeClock.Services.UtcTime
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.start_dependency(UtcTime, %{refresh_interval: 1, precision: :microsecond})
  end

  test "clock works" do
    refute_received({UtcTime, _})
    initial_time = Dependency.subscribe(UtcTime)
    assert_receive_dependency({UtcTime, current_time})
    assert :gt = DateTime.compare(current_time, initial_time)
    flush_messages()
    Dependency.unsubscribe(UtcTime)
    refute_receive_dependency({UtcTime, _current_time}, 10)
  end
end
