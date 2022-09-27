defmodule ExshomeAutomationTest.Web.AutomationsTest do
  use ExshomeWebTest.ConnCase, async: true

  describe "render without dependencies" do
    test "works fine", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeAutomation.path(conn, :automations))
    end
  end
end
