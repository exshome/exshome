defmodule ExshomeWebTest.Live.ServicePage.PlayerPageTest do
  use ExshomeWeb.ConnCase, async: true
  alias ExshomeWeb.Live.ServicePage.PlayerPage

  describe "player page index" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, PlayerPage.path(conn, :index))
    end
  end

  describe "player page settings" do
    test "renders without dependencies", %{conn: conn} do
      assert {:ok, _view, _html} = live(conn, PlayerPage.path(conn, :settings))
    end
  end

  describe "player page preview" do
    test "renders without dependencies", %{conn: conn} do
      assert live_preview(conn, PlayerPage)
    end
  end
end
