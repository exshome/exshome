defmodule ExshomeWeb.Live.Clock.Index do
  @moduledoc """
  Clock view for the application.
  """
  use ExshomeWeb, :live_view
  alias Phoenix.LiveView.Socket

  @time_refresh_interval 200
  @time_refresh_key :refresh_time

  @impl Phoenix.LiveView
  def mount(_params, _session, %Socket{} = socket) do
    {:ok, update_time(socket)}
  end

  @impl Phoenix.LiveView
  def handle_params(_unsigned_params, _url, %Socket{} = socket) do
    {:noreply, socket}
  end

  def update_time(%Socket{} = socket) do
    schedule_tick(self(), @time_refresh_interval)
    assign(socket, time: DateTime.utc_now())
  end

  def schedule_tick(pid, timeout) do
    Process.send_after(pid, @time_refresh_key, timeout)
  end

  @impl Phoenix.LiveView
  def handle_info(@time_refresh_key, %Socket{} = socket) do
    {:noreply, update_time(socket)}
  end
end
