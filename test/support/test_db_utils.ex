defmodule ExshomeTest.TestDbUtils do
  @moduledoc """
  Starts own database instance for each test.
  """
  alias Exqlite.Sqlite3

  def start_test_db do
    {:ok, repo} =
      Exshome.Repo.config()
      |> Keyword.merge(
        database: ":memory:",
        name: nil,
        pool_size: 1
      )
      |> Exshome.Repo.start_link()

    load_schema(repo)
    Exshome.Repo.put_dynamic_repo(repo)
  end

  defp load_schema(repo) do
    %{pid: pool_pid} = Ecto.Repo.Registry.lookup(repo)

    {:ok, pool_ref, _, _, %Exqlite.Connection{db: db}} =
      DBConnection.Holder.checkout(pool_pid, [], [])

    :ok = Sqlite3.deserialize(db, db_binary())
    :ok = DBConnection.Holder.checkin(pool_ref)
  end

  defp db_binary do
    case :persistent_term.get(__MODULE__, :empty) do
      :empty ->
        binary = extract_db_binary()
        :persistent_term.put(__MODULE__, binary)
        binary

      binary when is_binary(binary) ->
        binary
    end
  end

  defp extract_db_binary do
    {:ok, conn} = Sqlite3.open(Exshome.Repo.config()[:database])
    {:ok, binary} = Sqlite3.serialize(conn)
    Sqlite3.close(conn)
    binary
  end
end
