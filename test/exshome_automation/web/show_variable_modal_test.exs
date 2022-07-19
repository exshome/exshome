defmodule ExshomeAutomationTest.Web.ShowVariableModalTest do
  use ExshomeWeb.ConnCase, async: true

  alias Exshome.Dependency
  alias Exshome.Variable.VariableStateEvent
  alias ExshomePlayer.Services.MpvSocket
  alias ExshomePlayer.Services.PlayerState
  alias ExshomePlayer.Variables.Position
  alias ExshomePlayer.Variables.Volume
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry
  import ExshomeTest.Fixtures

  setup %{conn: conn} do
    TestMpvServer.server_fixture()
    TestRegistry.start_dependency(MpvSocket)
    TestRegistry.start_dependency(PlayerState)
    TestRegistry.start_dependency(Position)
    TestRegistry.start_dependency(Volume)
    view = live_with_dependencies(conn, ExshomeAutomation, :variables)
    %{view: view}
  end

  test "works fine", %{view: view} do
    assert Dependency.get_value(Volume) == 0
    open_modal(view, Volume)

    assert change_form(view, "some_invalid_value") =~ "Invalid value"

    unique_volume = Enum.random(1..100)
    assert change_form(view, "#{unique_volume}")
    assert_receive_app_page_dependency({Volume, _})
    assert Dependency.get_value(Volume) == unique_volume
  end

  test "refreshes variable config", %{view: view} do
    open_modal(view, Position)
    refute view |> find_form() |> has_element?()
    Dependency.broadcast_value(PlayerState, %PlayerState{path: "some_path#{unique_integer()}"})
    asser_variable_config_changed()
    assert view |> find_form() |> has_element?()
    Dependency.broadcast_value(PlayerState, Dependency.NotReady)
    asser_variable_config_changed()
    refute view |> find_form() |> has_element?()
  end

  defp open_modal(view, variable) do
    variable_id = Dependency.dependency_id(variable)

    view
    |> element("[phx-click=show_variable][phx-value-id='#{variable_id}']")
    |> render_click()
  end

  defp change_form(view, data) do
    view
    |> find_form()
    |> render_change(%{variable: data})
  end

  defp find_form(view), do: view |> find_live_child("modal-data") |> form("form")

  defp asser_variable_config_changed do
    assert_receive_app_page_event(%VariableStateEvent{})
  end
end
