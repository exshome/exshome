defmodule ExshomeWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use ExshomeWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ExshomeWeb.ConnCase

      alias ExshomeWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint ExshomeWeb.Endpoint
    end
  end

  setup tags do
    ExshomeTest.TestRegistry.allow(self(), self())
    ExshomeTest.TestFileUtils.generate_test_folder(tags)
    ExshomeTest.TestDbUtils.start_test_db()

    conn = Phoenix.ConnTest.build_conn()
    key = :live_view_connect_info

    connect_info =
      (conn.private[key] || %{})
      |> Map.put(:owner_pid, self())

    conn = Plug.Conn.put_private(conn, key, connect_info)

    {:ok, conn: conn}
  end
end
