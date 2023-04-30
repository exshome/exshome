defmodule ExshomeWeb.Live.Navigation do
  @moduledoc """
  Adds navigation support for every live page.
  """

  alias ExshomeWeb.Router.Helpers, as: Routes
  alias Phoenix.Component
  alias Phoenix.LiveView.Socket

  defstruct [:icon, :name, :path, :selected]

  @type t() :: %__MODULE__{
          icon: String.t(),
          name: String.t(),
          path: String.t(),
          selected: boolean()
        }

  def on_mount(:default, params, _session, %Socket{view: view} = socket) do
    params = route_params(params)

    navigation =
      if function_exported?(view, :app_module, 0) && params do
        app_navigation(socket, params)
      else
        []
      end

    socket =
      Component.assign(
        socket,
        :__navigation__,
        navigation
      )

    {:cont, socket}
  end

  defp app_navigation(%Socket{} = socket, %{action: action}) do
    app_module = socket.view.app_module()

    app_pages =
      for {page, _} <- app_module.pages() do
        %__MODULE__{
          icon: page.icon(),
          name: page.action(),
          selected: page.action() == action,
          path: app_module.path(socket, page.action())
        }
      end

    [
      %__MODULE__{
        icon: "hero-home-mini",
        name: "home",
        selected: false,
        path: Routes.home_path(socket, :index)
      }
      | app_pages
    ]
  end

  defp route_params(%{"app" => app, "action" => action, "id" => id}) do
    %{app: app, action: action, id: id}
  end

  defp route_params(%{"app" => app, "action" => action}) do
    %{app: app, action: action}
  end

  defp route_params(_), do: nil
end
