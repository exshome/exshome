defmodule ExshomePlayerTest.Web.PreviewTest do
  use ExshomeWebTest.ConnCase, async: true

  alias ExshomePlayer.Live.Preview

  test "renders without dependencies", %{conn: conn} do
    assert {:ok, _, _} = live_isolated(conn, Preview, [])
  end
end
