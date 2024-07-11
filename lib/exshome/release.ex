defmodule Exshome.Release do
  @moduledoc """
  Features related to the application releases.
  """

  @app :exshome

  def migrate do
    for repo <- repos() do
      create_db_if_not_exists(repo)
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def rollback(repo, version) do
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.load(@app)
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp create_db_if_not_exists(repo) do
    true = repo.__adapter__().storage_up(repo.config()) in [:ok, {:error, :already_up}]
  end
end
