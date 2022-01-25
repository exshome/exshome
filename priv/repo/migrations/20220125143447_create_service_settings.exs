defmodule Exshome.Repo.Migrations.CreateServiceSettings do
  use Ecto.Migration

  def change do
    create table(:service_settings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :settings, :map

      timestamps()
    end
  end
end
