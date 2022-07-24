defmodule Exshome.Repo.Migrations.CreateDynamicVariables do
  use Ecto.Migration

  def change do
    create table(:dynamic_variables) do
      add :name, :string, null: false, default: ""
      add :opts, :map, null: false, default: %{}
      add :type, :string, null: false
      add :value, :string
      add :version, :integer

      timestamps()
    end
  end
end
