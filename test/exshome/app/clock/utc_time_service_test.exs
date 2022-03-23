defmodule ExshomeTest.App.Clock.UtcTimeServiceTest do
  use ExUnit.Case, async: true
  alias Exshome.App.Clock.UtcTimeService
  alias Exshome.Dependency
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.allow(self(), self())
    TestRegistry.start_dependency(UtcTimeService, %{refresh_interval: 1, precision: :microsecond})
  end

  test "clock works" do
    refute_received({UtcTimeService, _})
    initial_time = Dependency.subscribe(UtcTimeService)
    assert_receive({UtcTimeService, current_time})
    assert :gt = DateTime.compare(current_time, initial_time)
    clear_received_messages()
    Dependency.unsubscribe(UtcTimeService)
    refute_receive({UtcTimeService, _current_time}, 10)
  end

  defp clear_received_messages do
    receive do
      _ -> clear_received_messages()
    after
      0 -> nil
    end
  end
end
