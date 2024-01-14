defmodule ExshomeWeb.Live.Navigation do
  @moduledoc """
  Adds navigation support for every live page.
  """

  alias Phoenix.Component
  alias Phoenix.LiveView.Socket

  defstruct [:icon, :name, :path, :selected]

  @type t() :: %__MODULE__{
          icon: String.t(),
          name: String.t(),
          path: String.t(),
          selected: boolean()
        }

  def on_mount(:default, _params, _session, %Socket{} = socket) do
    socket =
      if function_exported?(socket.router, :__router_config__, 0) do
        Phoenix.LiveView.attach_hook(
          socket,
          __MODULE__,
          :handle_params,
          &handle_params/3
        )
      else
        socket
      end

    {:cont, socket}
  end

  defp handle_params(_params, uri, %Socket{} = socket) do
    path = URI.parse(uri).path

    navigation =
      socket.router.__router_config__()
      |> Keyword.fetch!(:navbar)
      |> app_navigation(path, socket.view)

    {:cont, Component.assign(socket, __navigation__: navigation)}
  end

  defp app_navigation(navbar_items, path, view) do
    app_pages =
      for item <- navbar_items do
        extra_views = Keyword.get(item, :extra_views, [])
        item_path = Keyword.fetch!(item, :path)
        selected = view in extra_views || item_path == path

        %__MODULE__{
          icon: Keyword.fetch!(item, :icon),
          name: Keyword.fetch!(item, :name),
          selected: selected,
          path: item_path
        }
      end

    [
      %__MODULE__{
        icon: "hero-home-mini",
        name: "home",
        selected: false,
        path: "/"
      }
      | app_pages
    ]
  end
end
