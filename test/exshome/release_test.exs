defmodule ExshomeTest.ReleaseTest do
  use ExshomeTest.DataCase, async: true

  test "we can run migrations" do
    Exshome.Release.migrate()
  end
end
