defmodule ExshomePlayerTest.Web.PreviewTest do
  use ExshomeWebTest.ConnCase, async: true

  test "renders without dependencies", %{conn: conn} do
    assert live_preview(conn, ExshomePlayer)
  end
end
