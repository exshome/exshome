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
  def live_with_dependencies(%Plug.Conn{} = conn, service_page, action)
      when is_atom(service_page) and is_atom(action) do
    supervised_dependencies =
      service_page.actions()
      |> Map.get(action)
      |> Map.keys()
      |> Enum.filter(&function_exported?(&1, :child_spec, 1))

    for dependency <- supervised_dependencies do
      ExshomeTest.TestRegistry.start_dependency(dependency)
    end

    {:ok, view, _html} =
      live(
        conn,
        service_page.path(conn, action)
      )

    view
  end
end
