defmodule ExshomeAutomationTest.Web.AutomationsTest do
  use ExshomeWebTest.ConnCase, async: true
  alias ExshomeAutomation.Services.WorkflowRegistry
  import ExshomeTest.WorkflowHelpers

  describe "render without dependencies" do
    test "works fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeAutomation.path(conn, "automations"))
    end
  end

  describe "render with dependencies" do
    setup %{conn: conn} do
      start_workflow_supervisor()
      view = render_workflows(conn)
      %{view: view}
    end

    test "workflow lifecycle", %{view: view} do
      assert count_workflows(view) == 0
      create_new_workflow(view)
      assert count_workflows(view) == 1

      [id] = workflow_ids(view)
      delete_workflow(view, id)
      assert count_workflows(view) == 0
    end
  end

  defp render_workflows(conn) do
    live_with_dependencies(conn, ExshomeAutomation, "automations")
  end

  defp workflow_ids(view) do
    view
    |> render()
    |> Floki.attribute("button[phx-click=delete_workflow]", "phx-value-id")
  end

  defp count_workflows(view) do
    view
    |> workflow_ids()
    |> length()
  end

  defp create_new_workflow(view) do
    flush_messages()

    view
    |> form("form[phx-submit='new_workflow']")
    |> render_submit()

    assert_receive_app_page_dependency({WorkflowRegistry, _})
  end

  defp delete_workflow(view, id) do
    flush_messages()

    view
    |> element("[phx-click=delete_workflow][phx-value-id=#{id}]")
    |> render_click()

    assert_receive_app_page_dependency({WorkflowRegistry, _})
  end
end
