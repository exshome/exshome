defmodule ExshomeWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use ExshomeWeb, :controller
      use ExshomeWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: ExshomeWeb

      import Plug.Conn
      use Gettext, backend: ExshomeWeb.Gettext
      unquote(verified_routes())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(html_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        container: {:div, [class: "h-full"]},
        layout: {ExshomeWeb.Layouts, :app}

      extra_hooks = Application.compile_env(:exshome, :hooks, [])[:live_view] || []

      for module <- extra_hooks do
        on_mount module
      end

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      alias Phoenix.LiveComponent
      use LiveComponent

      unquote(html_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      use Gettext, backend: ExshomeWeb.Gettext
    end
  end

  defp html_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      use Phoenix.Component

      # Shortcut to generate JS commands
      alias Phoenix.LiveView.JS

      use Gettext, backend: ExshomeWeb.Gettext
      import ExshomeWeb.CoreComponents
      import ExshomeWeb.DatatypeComponent, only: [datatype_value: 1, datatype_input: 1]
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: ExshomeWeb.Endpoint,
        router: ExshomeWeb.Router,
        statics: ExshomeWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
