defmodule ExshomeAutomationTest.Web.PreviewTest do
  use ExshomeWeb.ConnCase, async: true
  alias ExshomeAutomation.Services.AutomationStatus
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomePlayer.Variables.Pause
  alias ExshomeTest.TestRegistry

  describe "render without dependencies" do
    test "can render", %{conn: conn} do
      assert live_preview(conn, ExshomeAutomation)
    end
  end

  describe "render with dependencies" do
    setup do
      TestRegistry.start_dependency(VariableRegistry)
    end

    test "works fine", %{conn: conn} do
      view = live_preview_with_dependencies(conn, ExshomeAutomation)
      assert render(view) =~ "Automation"
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
    assert_receive_app_page_dependency({AutomationStatus, _})
  end

  defp stop_variable do
    flush_messages()
    TestRegistry.stop_dependency(Pause)
    assert_receive_app_page_dependency({AutomationStatus, _})
  end

  defp count_variables(view) do
    view
    |> render()
    |> Floki.find("[type='total_variables']")
    |> Floki.text()
    |> String.to_integer()
  end
end
