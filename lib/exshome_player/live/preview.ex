defmodule ExshomePlayer.Live.Preview do
  @moduledoc """
  Player preview widget.
  """
  alias ExshomePlayer.Variables

  use ExshomeWeb.Live.AppPage,
    dependencies: [
      {Variables.Pause, :pause},
      {Variables.Title, :title}
    ]

  @impl LiveView
  def render(assigns) do
    ~H"""
    <.missing_deps_placeholder deps={@deps}>
      <div class="h-full w-full flex items-center justify-center flex-col p-3">
        <marquee class="text-2xl font-black w-full">
          <%= @deps.title %>
        </marquee>
        <div class="m-2 h-[45%] w-[45%] rounded-lg
              bg-gray-300 dark:bg-gray-800
              shadow-lg dark:shadow-gray-600 border-2 border-blue-300
              text-orange-600 flex items-center">
          <.icon
            name={if @deps.pause, do: "hero-play-solid", else: "hero-pause-solid"}
            class="p-[50%]"
          />
        </div>
      </div>
    </.missing_deps_placeholder>
    """
  end
end
