defmodule ExshomeTest.TestDbUtils do
  @moduledoc """
  Starts own database instance for each test.
  """

  def start_test_db do
    new_db_file = copy_database_to_test_folder()

    db_config =
      Application.get_env(:exshome, Exshome.Repo)
      |> Keyword.merge(database: new_db_file, name: nil)

    {:ok, repo} = Exshome.Repo.start_link(db_config)
    Exshome.Repo.put_dynamic_repo(repo)
  end

  @spec copy_database_to_test_folder() :: String.t()
  defp copy_database_to_test_folder do
    root_folder = Application.get_env(:exshome, :root_folder)
    source_db = Application.get_env(:exshome, Exshome.Repo) |> Keyword.fetch!(:database)

    destination_db =
      Path.join([
        ExshomeTest.TestFileUtils.get_test_folder(),
        Path.relative_to(source_db, root_folder)
      ])

    source_db_folder = Path.dirname(source_db)
    destination_db_folder = Path.dirname(destination_db)
    File.mkdir_p!(destination_db_folder)

    for file <- Path.wildcard("#{source_db}*") do
      file_name = Path.relative_to(file, source_db_folder)
      destination = Path.join(destination_db_folder, file_name)
      File.copy!(file, destination)
    end

    destination_db
  end
end
