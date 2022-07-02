defmodule ExshomeAutomationTest.WebTest do
  use ExshomeWeb.ConnCase, async: true

  describe "automation page index" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, ExshomeAutomation.path(conn, :index))
    end

    test "renders with dependencies", %{conn: conn} do
      view = live_with_dependencies(conn, ExshomeAutomation, :index)
      assert render(view) =~ "Variables"
    end
  end

  describe "automation page preview" do
    test "renders without dependencies", %{conn: conn} do
      assert live_preview(conn, ExshomeAutomation)
    end

    test "renders with dependencies", %{conn: conn} do
      view = live_preview_with_dependencies(conn, ExshomeAutomation)
      assert render(view) =~ "Automation"
    end
  end
end
