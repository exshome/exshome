defmodule ExshomeAutomation.Web.Live.Automations do
  @moduledoc """
  Automations page
  """

  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Services.WorkflowRegistry

  use ExshomeWeb.Live.AppPage,
    dependencies: [{WorkflowRegistry, :workflows}],
    icon: "🤖"

  @impl LiveView
  def handle_event("new_workflow", _, %Socket{} = socket) do
    :ok = Workflow.create!()
    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("delete_workflow", %{"id" => id}, %Socket{} = socket) do
    :ok = Workflow.delete!(id)
    {:noreply, socket}
  end
end
