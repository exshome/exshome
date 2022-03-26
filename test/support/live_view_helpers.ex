defmodule ExshomeTest.LiveViewHelpers do
  @moduledoc """
  API to help testing live views.
  """

  @endpoint ExshomeWeb.Endpoint
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @doc """
  Renders a live service page and returns a view. Raises when something bad happens.
  """
  @spec live_with_dependencies(Plug.Conn.t(), module(), atom()) :: Phoenix.LiveViewTest.View
  def live_with_dependencies(%Plug.Conn{} = conn, service_module, action)
      when is_atom(service_module) and is_atom(action) do
    start_dependencies(service_module, action)

    {:ok, view, _html} = live(conn, service_module.path(conn, action))

    view
  end

  @doc """
  Renders a preview for service page and returns a view. Raises when something bad happens.
  """
  @spec live_preview(Plug.Conn.t(), module()) :: Phoenix.LiveViewTest.View
  def live_preview(%Plug.Conn{} = conn, service_module) when is_atom(service_module) do
    {:ok, view, _html} =
      live_isolated(
        conn,
        ExshomeWeb.Live.ServicePreview,
        session: %{"name" => service_module.name()}
      )

    view
  end

  @doc """
  Starts dependencies and renders a preview for service page.
  Returns a view. Raises when something bad happens.
  """
  @spec live_preview_with_dependencies(Plug.Conn.t(), module()) :: Phoenix.LiveViewTest.View
  def live_preview_with_dependencies(%Plug.Conn{} = conn, service_module)
      when is_atom(service_module) do
    start_dependencies(service_module, :preview)
    live_preview(conn, service_module)
  end

  @spec start_dependencies(module(), atom()) :: :ok
  def start_dependencies(service_module, action)
      when is_atom(service_module) and is_atom(action) do
    supervised_dependencies =
      service_module.actions()
      |> Map.get(action)
      |> Map.keys()
      |> Enum.filter(&function_exported?(&1, :child_spec, 1))

    for dependency <- supervised_dependencies do
      ExshomeTest.TestRegistry.start_dependency(dependency)
    end

    :ok
  end
end
