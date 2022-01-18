defmodule ExshomeTest.Service.ClockServiceTest do
  use ExUnit.Case, async: true
  alias Exshome.Service.ClockService
  alias ExshomeTest.TestRegistry

  setup do
    TestRegistry.allow(self(), self())
    TestRegistry.start_service(ClockService, %{refresh_interval: 1, precision: :microsecond})
  end

  test "clock works" do
    refute_received({ClockService, _})
    initial_time = ClockService.subscribe()
    assert_receive({ClockService, current_time})
    assert :gt = DateTime.compare(current_time, initial_time)
    clear_received_messages()
    ClockService.unsubscribe()
    refute_receive({ClockService, _current_time}, 10)
  end

  defp clear_received_messages do
    receive do
      _ -> clear_received_messages()
    after
      0 -> nil
    end
  end
end
