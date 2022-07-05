defmodule ExshomeAutomationTest.Web.IndexTest do
  use ExshomeWeb.ConnCase, async: true

  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomePlayer.Variables.Pause
  alias ExshomeTest.TestRegistry

  describe "render without dependencies" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeAutomation.path(conn, :index))
    end
  end

  describe "render with dependnencies" do
    test "works fine", %{conn: conn} do
      view = live_with_dependencies(conn, ExshomeAutomation, :index)
      assert render(view) =~ "Variables"
      assert count_variables(view) == 0
      start_variable()
      assert count_variables(view) == 1
      stop_variable()
      assert count_variables(view) == 0
    end
  end

  defp start_variable do
    flush_messages()
    TestRegistry.start_dependency(Pause)
    assert_receive_app_page_dependency({VariableRegistry, _})
  end

  defp stop_variable do
    flush_messages()
    TestRegistry.stop_dependency(Pause)
    assert_receive_app_page_dependency({VariableRegistry, _})
  end

  defp count_variables(view) do
    view
    |> render()
    |> Floki.find("li")
    |> length()
  end
end
