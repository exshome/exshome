defmodule ExshomeWeb.Router do
  use ExshomeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {ExshomeWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :browser

    live "/", ExshomeWeb.Live.HomePage, :index, as: :home

    for module <- Exshome.App.apps() do
      for page <- module.pages() do
        path = Path.join("/#{module.prefix()}", page.path())
        live(path, page, page.action(), as: module.prefix())
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExshomeWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExshomeWeb.Telemetry
    end
  end
end
