defmodule ExshomeTest.ReleaseTest do
  use Exshome.DataCase, async: true

  test "we can run migrations" do
    Exshome.Release.migrate()
  end
end
