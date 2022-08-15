defmodule ExshomeAutomationTest.Web.AutomationsTest do
  use ExshomeWeb.ConnCase, async: true

  describe "render without dependencies" do
    test "renders fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeAutomation.path(conn, :automations))
    end
  end
end
