defmodule ExshomeAutomationTest.Live.ShowVariableModalTest do
  use ExshomeWebTest.ConnCase, async: true

  alias Exshome.DataStream.Operation
  alias Exshome.Datatype
  alias Exshome.Dependency
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias Exshome.Variable
  alias Exshome.Variable.VariableStateStream
  alias ExshomeAutomation.Live.Variables
  alias ExshomeAutomation.Services.VariableRegistry
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
      start_app_page_dependencies(Variables)
      {:ok, view, _html} = live(conn, "/app/automation/variables")
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
      Emitter.broadcast(PlayerState, %PlayerState{path: "some_path#{unique_integer()}"})
      assert_variable_config_changed(Position)
      assert view |> find_update_value_form() |> has_element?()
      Emitter.broadcast(PlayerState, NotReady)
      assert_variable_config_changed(Position)
      refute view |> find_update_value_form() |> has_element?()
    end
  end

  describe "custom variables" do
    setup %{conn: conn} do
      start_dynamic_variable_supervisor()
      start_app_page_dependencies(Variables)
      {:ok, view, _html} = live(conn, "/app/automation/variables")
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

    test "deletes a variable when modal is open", %{view: view} do
      create_new_variable(view, Enum.random(Datatype.available_types()))

      assert_receive_app_page_stream(
        {VariableStateStream,
         %Operation.Insert{data: %Variable{id: variable_id, dependency: dependency}}}
      )

      open_modal(view, dependency)
      :ok = Variable.delete_by_id!(variable_id)
      assert_receive_app_page_dependency({VariableRegistry, _})
      refute render(view) =~ variable_id
    end

    defp create_new_variable(view, datatype) do
      datatype_name = Exshome.Datatype.name(datatype)

      view
      |> form("form[phx-submit='new-variable']")
      |> render_submit(%{type: datatype_name})
    end
  end

  defp open_modal(view, variable) do
    variable_id = Dependency.dependency_id(variable)

    view
    |> element("[phx-click='edit-variable'][phx-value-id='#{variable_id}']")
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
    |> render_change(%{new_name: name})
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
    |> form("form[phx-change='rename_variable']")
  end

  defp assert_variable_config_changed(variable) do
    variable_id = Dependency.dependency_id(variable)
    assert_receive_app_page_stream({{VariableStateStream, ^variable_id}, %Operation.Update{}})
  end
end
