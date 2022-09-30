defmodule ExshomeAutomation.Schemas.AutomationWorkflow do
  @moduledoc """
  Schema for storing automation workflow data.
  """
  use Exshome.Schema

  schema "automation_workflows" do
    field(:name, :string, default: "")
    field(:version, :integer)

    timestamps()
  end
end
