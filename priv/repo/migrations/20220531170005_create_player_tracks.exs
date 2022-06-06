defmodule Exshome.Repo.Migrations.CreatePlayerTracks do
  use Ecto.Migration

  def change do
    create table(:player_tracks) do
      add :title, :string, null: false, default: ""
      add :type, :string, null: false, default: "file"
      add :path, :string, null: false

      timestamps()

      unique_index(:player_tracks, [:path])
    end
  end
end
