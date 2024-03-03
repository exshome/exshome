defmodule ExshomeAutomationTest.Live.PreviewTest do
  use ExshomeWebTest.ConnCase, async: true

  alias Exshome.Emitter
  alias ExshomeAutomation.Live.Preview
  alias ExshomeAutomation.Services.AutomationStatus
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Services.WorkflowRegistry
  alias ExshomePlayer.Services.PlayerState
  alias ExshomePlayer.Variables.Volume
  alias ExshomeTest.TestRegistry

  describe "render without dependencies" do
    test "can render", %{conn: conn} do
      assert {:ok, _view, _html} = live_isolated(conn, Preview, [])
    end
  end

  describe "render with dependencies" do
    setup do
      TestRegistry.start_dependency(VariableRegistry)
      TestRegistry.start_dependency(WorkflowRegistry)
    end

    test "works fine", %{conn: conn} do
      start_app_page_dependencies(Preview)
      {:ok, view, _html} = live_isolated(conn, Preview, [])
      assert render(view) =~ "Automation"
      assert count_variables(view, "not_ready_variables") == 0
      assert count_variables(view, "ready_variables") == 0
      start_variable()
      assert count_variables(view, "not_ready_variables") == 1
      assert count_variables(view, "ready_variables") == 0
      make_variable_ready()
      assert count_variables(view, "not_ready_variables") == 0
      assert count_variables(view, "ready_variables") == 1
      stop_variable()
      assert count_variables(view, "not_ready_variables") == 0
      assert count_variables(view, "ready_variables") == 0
    end
  end

  defp start_variable do
    flush_messages()
    TestRegistry.start_dependency(Volume)
    assert_receive_app_page_dependency({AutomationStatus, _})
  end

  defp stop_variable do
    flush_messages()
    TestRegistry.stop_dependency(Volume)
    assert_receive_app_page_dependency({AutomationStatus, _})
  end

  defp count_variables(view, type) do
    view
    |> render()
    |> Floki.find("[type='#{type}']")
    |> Floki.text()
    |> String.to_integer()
  end

  defp make_variable_ready do
    flush_messages()
    assert :ok = Emitter.broadcast(PlayerState, %PlayerState{})
    assert_receive_app_page_dependency({AutomationStatus, _})
  end
end
