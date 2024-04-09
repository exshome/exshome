defmodule ExshomeTest.LiveViewHelpers do
  @moduledoc """
  API to help testing live views.
  """

  import Phoenix.LiveViewTest

  @doc """
  Extracts value from input element by selector.
  """
  def get_value(view, selector) do
    [value] = view |> render() |> Floki.attribute(selector, "value")
    value
  end

  @spec start_app_page_dependencies(module()) :: :ok
  def start_app_page_dependencies(app_page) when is_atom(app_page) do
    supervised_dependencies =
      app_page.dependencies()
      |> Keyword.keys()
      |> Enum.into(MapSet.new())
      |> Enum.map(&Code.ensure_loaded!/1)
      |> Enum.filter(&function_exported?(&1, :child_spec, 1))

    for dependency <- supervised_dependencies do
      ExshomeTest.TestRegistry.start_service(dependency)
    end

    :ok
  end
end
