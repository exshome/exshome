defmodule ExshomeAutomationTest.Live.VariablesTest do
  use ExshomeWebTest.ConnCase, async: true

  alias Exshome.Datatype
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias ExshomeAutomation.Live.Variables
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Variables.DynamicVariable.Schema
  alias ExshomePlayer.Variables.Pause
  alias ExshomeTest.TestRegistry

  import ExshomeTest.DynamicVariableHelpers

  describe "render without dependencies" do
    test "renders fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, "/app/automation/variables")
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
      assert get_dynamic_variable_value(id) != NotReady
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
        assert_receive_app_page_dependency({VariableRegistry, _})
        assert count_variables(view) == 1

        variable_id =
          VariableRegistry
          |> Dependency.get_value()
          |> Map.keys()
          |> List.first()

        flush_messages()
        delete_dynamic_variable(view, variable_id)
        assert_receive_app_page_dependency({VariableRegistry, _})
        assert count_variables(view) == 0
      end
    end
  end

  defp render_variables_list(conn) do
    start_app_page_dependencies(Variables)
    {:ok, view, _html} = live(conn, "/app/automation/variables")
    view
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
    |> element("[phx-click='delete-variable'][phx-value-id$='#{id}']")
    |> render_click()
  end

  defp create_new_variable(view, datatype) do
    datatype_name = Exshome.Datatype.name(datatype)

    view
    |> form("form[phx-submit='new-variable']")
    |> render_submit(%{type: datatype_name})
  end
end
