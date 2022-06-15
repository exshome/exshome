defmodule ExshomePlayerTest.Web.PreviewTest do
  use ExshomeWeb.ConnCase, async: true

  test "renders without dependencies", %{conn: conn} do
    assert live_preview(conn, ExshomePlayer)
  end
end
