defmodule ExshomeClock.Services.UtcTime do
  @moduledoc """
  UTC time dependency.
  """
  use Exshome.Service.DependencyService, app: ExshomeClock, name: "utc_time"

  @impl ServiceBehaviour
  def init(state) do
    schedule_next_tick(state)
  end

  @impl ServiceBehaviour
  def handle_info(:tick, state) do
    new_state = schedule_next_tick(state)
    {:noreply, new_state}
  end

  def schedule_next_tick(%ServiceState{} = state) do
    update_interval = refresh_interval(state)
    Process.send_after(self(), :tick, update_interval)
    new_value = DateTime.truncate(DateTime.utc_now(), precision(state))
    update_value(state, fn _ -> new_value end)
  end

  defp refresh_interval(%ServiceState{opts: opts}), do: opts[:refresh_interval] || 200
  defp precision(%ServiceState{opts: opts}), do: opts[:precision] || :second
end
