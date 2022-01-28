defmodule Exshome.Repo.Migrations.CreateServiceSettings do
  use Ecto.Migration

  def change do
    create table(:service_settings, primary_key: false) do
      add :name, :string, primary_key: true
      add :data, :map, null: false, default: %{}
      add :version, :integer

      timestamps()
    end
  end
end
