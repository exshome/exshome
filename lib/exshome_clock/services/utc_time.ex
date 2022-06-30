defmodule ExshomeClock.Services.UtcTime do
  @moduledoc """
  UTC time dependency.
  """
  use Exshome.Dependency.GenServerDependency, name: "utc_time"

  @impl GenServerDependency
  def on_init(state) do
    schedule_next_tick(state)
  end

  @impl GenServerDependency
  def handle_info(:tick, state) do
    new_state = schedule_next_tick(state)
    {:noreply, new_state}
  end

  def schedule_next_tick(%DependencyState{} = state) do
    update_interval = refresh_interval(state)
    Process.send_after(self(), :tick, update_interval)
    new_value = DateTime.truncate(DateTime.utc_now(), precision(state))
    update_value(state, new_value)
  end

  defp refresh_interval(%DependencyState{opts: opts}), do: opts[:refresh_interval] || 200
  defp precision(%DependencyState{opts: opts}), do: opts[:precision] || :second
end
