defmodule ExshomeWeb.LayoutView do
  use ExshomeWeb, :view
  alias Phoenix.LiveView.Socket

  # Phoenix LiveDashboard is available only in development by default,
  # so we instruct Elixir to not warn if the dashboard route is missing.
  @compile {:no_warn_undefined, {Routes, :live_dashboard_path, 2}}

  def navigation_data(%Socket{view: view} = socket) do
    if function_exported?(view, :app_module, 0) do
      app_navigation(socket)
    else
      []
    end
  end

  defp app_navigation(%Socket{view: view} = socket) do
    app_pages =
      for {page, _} <- view.app_module().pages() do
        %{
          icon: page.icon(),
          name: page.action(),
          selected: view == page,
          path: view.app_module().path(socket, page.action())
        }
      end

    [
      %{
        icon: "🏠",
        name: "home",
        selected: false,
        path: Routes.home_path(socket, :index)
      }
      | app_pages
    ]
  end
end
