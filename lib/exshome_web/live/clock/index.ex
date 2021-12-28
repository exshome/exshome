defmodule ExshomeWeb.Live.Clock.Index do
  @moduledoc """
  Clock view for the application.
  """
  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @time_refresh_interval 200
  @time_refresh_key :time

  def mount(_params, _session, %Socket{} = socket) do
    {:ok, schedule_tick(socket)}
  end

  def schedule_tick(%Socket{} = socket) do
    Process.send_after(self(), @time_refresh_key, @time_refresh_interval)
    assign(socket, time: DateTime.utc_now())
  end

  def handle_info(@time_refresh_key, %Socket{} = socket) do
    {:noreply, schedule_tick(socket)}
  end
end
