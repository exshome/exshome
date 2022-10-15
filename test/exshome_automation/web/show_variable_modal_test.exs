defmodule ExshomeAutomationTest.Web.ShowVariableModalTest do
  use ExshomeWebTest.ConnCase, async: true

  alias Exshome.Datatype
  alias Exshome.Dependency
  alias Exshome.Variable
  alias Exshome.Variable.VariableStateEvent
  alias ExshomePlayer.Services.MpvSocket
  alias ExshomePlayer.Services.PlayerState
  alias ExshomePlayer.Variables.Position
  alias ExshomePlayer.Variables.Volume
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry
  import ExshomeTest.Fixtures
  import ExshomeTest.DynamicVariableHelpers

  describe "built-in variables" do
    setup %{conn: conn} do
      TestMpvServer.server_fixture()
      TestRegistry.start_dependency(MpvSocket)
      TestRegistry.start_dependency(PlayerState)
      TestRegistry.start_dependency(Position)
      TestRegistry.start_dependency(Volume)
      view = live_with_dependencies(conn, ExshomeAutomation, "variables")
      %{view: view}
    end

    test "works fine", %{view: view} do
      assert Dependency.get_value(Volume) == 0
      open_modal(view, Volume)

      assert update_value(view, "some_invalid_value") =~ "Invalid value"

      unique_volume = Enum.random(1..100)
      assert update_value(view, "#{unique_volume}")
      assert_receive_app_page_dependency({Volume, _})
      assert Dependency.get_value(Volume) == unique_volume
    end

    test "refreshes variable config", %{view: view} do
      open_modal(view, Position)
      refute view |> find_update_value_form() |> has_element?()
      Dependency.broadcast_value(PlayerState, %PlayerState{path: "some_path#{unique_integer()}"})
      assert_variable_config_changed()
      assert view |> find_update_value_form() |> has_element?()
      Dependency.broadcast_value(PlayerState, Dependency.NotReady)
      assert_variable_config_changed()
      refute view |> find_update_value_form() |> has_element?()
    end
  end

  describe "custom variables" do
    setup %{conn: conn} do
      start_dynamic_variable_supervisor()
      view = live_with_dependencies(conn, ExshomeAutomation, "variables")
      %{view: view}
    end

    test "renames variable", %{view: view} do
      create_new_variable(view, Enum.random(Datatype.available_types()))
      assert [%Variable{} = variable] = Variable.list()
      new_name = "some_name#{unique_integer()}"
      rename(view, new_name)
      assert {:ok, %Variable{name: ^new_name}} = Variable.get_by_id(variable.id)
      toggle_rename_input(view)
      assert view |> find_rename_form() |> render() =~ new_name
    end

    defp create_new_variable(view, datatype) do
      view
      |> form("form[phx-submit='new_variable']")
      |> render_submit(%{type: datatype.name()})
    end
  end

  defp open_modal(view, variable) do
    variable_id = Dependency.dependency_id(variable)

    view
    |> element("[phx-click=show_variable][phx-value-id='#{variable_id}']")
    |> render_click()
  end

  defp update_value(view, data) do
    view
    |> find_update_value_form()
    |> render_change(%{variable: data})
  end

  defp find_update_value_form(view) do
    view
    |> find_live_child("modal-data")
    |> form("form[phx-change='update_value']")
  end

  defp rename(view, name) do
    view
    |> find_rename_form()
    |> render_change(%{name: name})
  end

  defp toggle_rename_input(view) do
    view
    |> find_live_child("modal-data")
    |> element("button[phx-click='toggle_rename']")
    |> render_click()
  end

  defp find_rename_form(view) do
    view
    |> find_live_child("modal-data")
    |> form("form[phx-change='rename']")
  end

  defp assert_variable_config_changed do
    assert_receive_app_page_event(%VariableStateEvent{})
  end
end
