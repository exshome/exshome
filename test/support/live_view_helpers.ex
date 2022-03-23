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
  @spec live_with_dependencies(Plug.Conn.t(), module(), atom()) :: Phoenix.LiveViewTest.View.t()
  def live_with_dependencies(%Plug.Conn{} = conn, service_page, action)
      when is_atom(service_page) and is_atom(action) do
    service_page.actions()
    |> Map.get(action)
    |> Map.keys()
    |> Enum.each(&ExshomeTest.TestRegistry.start_dependency(&1))

    {:ok, view, _html} =
      live(
        conn,
        service_page.path(conn, action)
      )

    view
  end
end
