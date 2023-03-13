defmodule ExshomeWebTest.ConnCase do
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
  alias ExshomeWeb.App

  using do
    quote do
      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import ExshomeWebTest.ConnCase
      import Phoenix.LiveViewTest

      alias ExshomeWeb.Router.Helpers, as: Routes
      import ExshomeTest.LiveViewHelpers
      import ExshomeTest.TestHelpers

      # The default endpoint for testing
      @endpoint ExshomeWeb.Endpoint

      use ExshomeWeb, :verified_routes
    end
  end

  setup do
    ExshomeTest.TestRegistry.allow(self(), self())
    ExshomeTest.TestFileUtils.generate_test_folder()
    ExshomeTest.TestDbUtils.start_test_db()

    :ok = Exshome.SystemRegistry.register!(App, :available_apps, App.available_apps())

    conn = Phoenix.ConnTest.build_conn()
    key = :live_view_connect_info

    connect_info =
      (conn.private[key] || %{})
      |> Map.put(:owner_pid, self())

    conn = Plug.Conn.put_private(conn, key, connect_info)

    {:ok, conn: conn}
  end
end
