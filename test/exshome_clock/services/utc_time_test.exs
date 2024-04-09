defmodule ExshomeClockTest.Services.UtcTimeTest do
  use ExshomeTest.DataCase, async: true
  import ExshomeTest.TestHelpers

  alias Exshome.Dependency
  alias Exshome.Emitter
  alias ExshomeClock.Services.UtcTime
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.start_service(UtcTime, %{refresh_interval: 1, precision: :microsecond})
  end

  test "clock works" do
    refute_received({UtcTime, _})
    initial_time = Dependency.get_and_subscribe(UtcTime)
    assert_receive_dependency({UtcTime, current_time})
    assert :gt = DateTime.compare(current_time, initial_time)
    flush_messages()
    Emitter.unsubscribe(UtcTime)
    refute_receive_dependency({UtcTime, _current_time}, 10)
  end
end
