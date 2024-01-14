defmodule ExshomeClock.Live.Clock do
  @moduledoc """
  Main clock page.
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [{ExshomeClock.Services.LocalTime, :time}]

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <.missing_deps_placeholder deps={@deps}>
      <div class="flex dark:text-gray-300 min-h-full items-center justify-center flex-col">
        <div id="clock_time" class="text-[15vw]"><%= format_time(@deps.time) %></div>
        <div id="clock_date" class="text-[5vw]"><%= format_date(@deps.time) %></div>
      </div>
    </.missing_deps_placeholder>
    """
  end

  def format_time(%DateTime{} = data), do: Calendar.strftime(data, "%X")
  def format_date(%DateTime{} = data), do: Calendar.strftime(data, "%B %d, %Y")
end
