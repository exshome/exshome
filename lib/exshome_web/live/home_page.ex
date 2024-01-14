defmodule ExshomeWeb.Live.HomePage do
  @moduledoc """
  Live Home page for our application.
  """

  use ExshomeWeb, :live_view
  alias ExshomeWeb.App
  alias Phoenix.LiveView

  @impl LiveView
  def mount(_, _, %LiveView.Socket{} = socket) do
    apps =
      for app <- App.apps() do
        config = App.router_config_by_app(app)

        %{
          main_path: Keyword.fetch!(config, :main_path),
          id: Keyword.fetch!(config, :key),
          preview: Keyword.fetch!(config, :preview)
        }
      end

    {:ok, assign(socket, apps: apps)}
  end

  @impl LiveView
  def render(assigns) do
    ~H"""
    <div class="flex flex-wrap justify-center">
      <.link :for={app <- @apps} navigate={app.main_path}>
        <div class="
          w-[40vmin] h-[40vmin] lg:w-[30vmin] lg:h-[30vmin]
          p-2 m-2 relative
          border-2 border-gray-500 rounded-md overflow-hidden
          hover:bg-gray-200 dark:hover:bg-gray-800
          shadow-2xl dark:shadow-gray-600
      ">
          <div class="absolute inset-0"></div>
          <%= live_render(
            @socket,
            app.preview,
            id: app.id,
            container: {:div, class: "w-full h-full"}
          ) %>
        </div>
      </.link>
    </div>
    """
  end
end
