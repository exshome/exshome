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

  def controller do
    quote do
      use Phoenix.Controller, namespace: ExshomeWeb

      import Plug.Conn
      import ExshomeWeb.Gettext
      alias ExshomeWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      app_module =
        __MODULE__
        |> Module.split()
        |> Enum.slice(0..0)
        |> Module.safe_concat()

      use Phoenix.View,
        root: app_module.template_root(),
        namespace: app_module.namespace()

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def basic_live_view do
    quote do
      use Phoenix.LiveView,
        container: {:div, [class: "h-full"]},
        layout: {ExshomeWeb.LayoutView, "live.html"}
    end
  end

  def live_view do
    quote do
      unquote(basic_live_view())

      extra_hooks = Application.compile_env(:exshome, :hooks, [])[:live_view] || []

      for module <- extra_hooks ++ [ExshomeWeb.Live.Modal] do
        on_mount module
      end

      import ExshomeWeb.Live.Modal,
        only: [open_modal: 3, open_modal: 2, close_modal: 1, send_js: 2]

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      unquote(view_helpers())
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
      import ExshomeWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView and .heex helpers (live_render, live_patch, <.form>, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import ExshomeWeb.ErrorHelpers
      import ExshomeWeb.Gettext
      import ExshomeWeb.Components
      import ExshomeWeb.DatatypeView, only: [datatype_value: 1, datatype_input: 1]
      alias ExshomeWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  def template_root, do: "lib/exshome_web/templates"
  def namespace, do: __MODULE__
end
