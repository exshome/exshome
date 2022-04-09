defmodule ExshomeTest.App.Clock.UtcTimeTest do
  use Exshome.DataCase, async: true
  alias Exshome.App.Clock.UtcTime
  alias Exshome.Dependency
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.start_dependency(UtcTime, %{refresh_interval: 1, precision: :microsecond})
  end

  test "clock works" do
    refute_received({UtcTime, _})
    initial_time = Dependency.subscribe(UtcTime)
    assert_receive_dependency({UtcTime, current_time})
    assert :gt = DateTime.compare(current_time, initial_time)
    clear_received_messages()
    Dependency.unsubscribe(UtcTime)
    refute_receive_dependency({UtcTime, _current_time}, 10)
  end

  defp clear_received_messages do
    receive do
      _ -> clear_received_messages()
    after
      0 -> nil
    end
  end
end
