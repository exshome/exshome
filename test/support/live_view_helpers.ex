defmodule ExshomeTest.LiveViewHelpers do
  @moduledoc """
  API to help testing live views.
  """

  @endpoint ExshomeWeb.Endpoint
  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  @doc """
  Renders a live app page and returns a view. Raises when something bad happens.
  """
  @spec live_with_dependencies(
          Plug.Conn.t(),
          app_module :: module(),
          action :: String.t(),
          id :: String.t() | nil
        ) :: Phoenix.LiveViewTest.View
  def live_with_dependencies(%Plug.Conn{} = conn, app_module, action, id \\ nil)
      when is_atom(app_module) and is_binary(action) do
    start_dependencies(app_module, action, id)

    path =
      if id do
        app_module.details_path(conn, action, id)
      else
        app_module.path(conn, action)
      end

    {:ok, view, _html} = live(conn, path)

    view
  end

  @doc """
  Renders a preview for app page and returns a view. Raises when something bad happens.
  """
  @spec live_preview(Plug.Conn.t(), module()) :: Phoenix.LiveViewTest.View
  def live_preview(%Plug.Conn{} = conn, app_module) when is_atom(app_module) do
    module = app_page(app_module, "preview")
    {:ok, view, _html} = live_isolated(conn, module, [])

    view
  end

  @doc """
  Starts dependencies and renders a preview for app page.
  Returns a view. Raises when something bad happens.
  """
  @spec live_preview_with_dependencies(Plug.Conn.t(), module()) :: Phoenix.LiveViewTest.View
  def live_preview_with_dependencies(%Plug.Conn{} = conn, app_module)
      when is_atom(app_module) do
    start_dependencies(app_module, "preview")
    live_preview(conn, app_module)
  end

  @doc """
  Extracts value from input element by selector.
  """
  def get_value(view, selector) do
    [value] = view |> render() |> Floki.attribute(selector, "value")
    value
  end

  @spec start_dependencies(module(), action :: String.t(), id :: String.t() | nil) :: :ok
  def start_dependencies(app_module, action, id \\ nil)
      when is_atom(app_module) and is_binary(action) do
    supervised_dependencies =
      app_module
      |> app_page(action, id)
      |> then(& &1.dependencies())
      |> Keyword.keys()
      |> Enum.into(MapSet.new())
      |> Enum.map(&Code.ensure_loaded!/1)
      |> Enum.filter(&function_exported?(&1, :child_spec, 1))

    for dependency <- supervised_dependencies do
      ExshomeTest.TestRegistry.start_dependency(dependency)
    end

    :ok
  end

  defp app_page(app_module, action, id \\ nil)

  defp app_page(app_module, "preview", nil), do: app_module.preview()

  defp app_page(app_module, action, nil) do
    app_module.pages()
    |> Enum.map(fn {page, _} -> page end)
    |> Enum.filter(&(&1.action() == action))
    |> List.first() || raise "Unable to find app page for #{app_module}:#{action}"
  end

  defp app_page(app_module, action, id) do
    {_parent_page, children} =
      Enum.find(
        app_module.pages(),
        fn {page, _} -> page.action() == action end
      )

    {_pattern, page} =
      Enum.find(
        children,
        fn {pattern, _} -> String.match?(id, Regex.compile!(pattern)) end
      )

    page
  end
end
