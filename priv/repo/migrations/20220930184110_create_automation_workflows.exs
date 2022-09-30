defmodule Exshome.Repo.Migrations.CreateAutomationWorkflows do
  use Ecto.Migration

  def change do
    create table(:automation_workflows) do
      add :name, :string, null: false, default: ""
      add :version, :integer

      timestamps()
    end
  end
end
