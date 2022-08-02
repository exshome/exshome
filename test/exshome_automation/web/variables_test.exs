defmodule ExshomeAutomationTest.Web.VariablesTest do
  use ExshomeWeb.ConnCase, async: true

  alias Exshome.Datatype
  alias Exshome.Dependency
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Variables.DynamicVariable.Schema
  alias ExshomePlayer.Variables.Pause
  alias ExshomeTest.TestRegistry

  import ExshomeTest.DynamicVariableHelpers

  describe "render without dependencies" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeAutomation.path(conn, :variables))
    end
  end

  describe "render with dependnencies" do
    test "works fine", %{conn: conn} do
      view = render_variables_list(conn)
      refute render(view) =~ "player"
      assert count_variables(view) == 0
      start_variable()
      assert render(view) =~ "player"
      assert count_variables(view) == 1
      stop_variable()
      assert count_variables(view) == 0
    end
  end

  describe "invalid dynamic variable" do
    test "renders fine", %{conn: conn} do
      %Schema{id: id} = create_dynamic_variable_with_unknown_type()
      start_dynamic_variable_supervisor()
      assert get_dynamic_variable_value(id) != Dependency.NotReady
      view = render_variables_list(conn)
      assert count_variables(view) == 1
      delete_dynamic_variable(view, id)
      assert count_variables(view) == 0
    end
  end

  describe "creates dynamic variable" do
    setup %{conn: conn} do
      start_dynamic_variable_supervisor()
      view = render_variables_list(conn)
      %{view: view}
    end

    test "variable workflow", %{view: view} do
      for type <- Datatype.available_types() do
        assert count_variables(view) == 0
        create_new_variable(view, type)
        assert_receive_dependency({VariableRegistry, _})
        assert count_variables(view) == 1

        variable_id =
          VariableRegistry
          |> Dependency.get_value()
          |> Map.keys()
          |> List.first()

        delete_dynamic_variable(view, variable_id)
        assert count_variables(view) == 0
      end
    end
  end

  defp render_variables_list(conn) do
    live_with_dependencies(conn, ExshomeAutomation, :variables)
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

  defp delete_dynamic_variable(view, id) do
    view
    |> element("[phx-click='delete_variable'][phx-value-id$='#{id}']")
    |> render_click()
  end

  defp create_new_variable(view, datatype) do
    view
    |> form("form[phx-submit='new_variable']")
    |> render_submit(%{type: datatype.name()})
  end
end
