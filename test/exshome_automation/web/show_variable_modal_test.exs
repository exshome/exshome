defmodule ExshomeAutomationTest.Web.ShowVariableModalTest do
  use ExshomeWeb.ConnCase, async: true

  alias Exshome.Dependency
  alias ExshomePlayer.Services.MpvSocket
  alias ExshomePlayer.Services.PlayerState
  alias ExshomePlayer.Variables.Volume
  alias ExshomeTest.TestMpvServer
  alias ExshomeTest.TestRegistry

  setup %{conn: conn} do
    TestMpvServer.server_fixture()
    TestRegistry.start_dependency(MpvSocket)
    TestRegistry.start_dependency(PlayerState)
    TestRegistry.start_dependency(Volume)
    view = live_with_dependencies(conn, ExshomeAutomation, :variables)
    %{view: view}
  end

  test "works fine", %{view: view} do
    assert Dependency.get_value(Volume) == 0
    open_modal(view)

    assert change_form(view, "some_invalid_value") =~ "Invalid value"
    assert submit_data(view, "some_invalid_value") =~ "Invalid value"

    unique_volume = Enum.random(1..100)
    submit_data(view, "#{unique_volume}")
    assert_receive_app_page_dependency({Volume, _})
    assert Dependency.get_value(Volume) == unique_volume
  end

  defp open_modal(view) do
    view
    |> element("[phx-click=show_variable]")
    |> render_click()
  end

  defp change_form(view, data) do
    view
    |> find_form()
    |> render_change(%{variable: data})
  end

  defp submit_data(view, data) do
    view
    |> find_form()
    |> render_submit(%{variable: data})
  end

  defp find_form(view), do: view |> find_live_child("modal-data") |> form("form")
end
