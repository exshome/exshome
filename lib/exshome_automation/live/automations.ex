defmodule ExshomeAutomation.Live.Automations do
  @moduledoc """
  Automations page
  """

  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Services.WorkflowRegistry

  use ExshomeWeb.Live.AppPage,
    dependencies: [{WorkflowRegistry, :workflows}]

  @impl LiveView
  def render(assigns) do
    ~H"""
    <.missing_deps_placeholder deps={@deps}>
      <section class="h-full max-h-full w-full p-4 flex flex-col overflow-hidden">
        <form class="mb-3 w-full flex items-center justify-center" phx-submit="new_workflow">
          <.button type="submit" phx-disable-with="Creating..." class="whitespace-nowrap">
            New workflow
          </.button>
        </form>
        <section class="flex-grow h-full flex items-center overflow-auto">
          <div class="w-full max-h-full">
            <.list
              :let={workflow}
              rows={@deps.workflows |> Map.values() |> Enum.sort_by(&{&1.name, &1.id})}
            >
              <:row_before :let={workflow}>
                <%= if workflow.active do %>
                  <.icon name="hero-check-circle-solid" class="text-green-700 p-3" />
                <% else %>
                  <.icon name="hero-exclamation-triangle-solid" class="text-orange-400 p-3" />
                <% end %>
              </:row_before>
              <:row_after :let={workflow}>
                <.button
                  phx-click={JS.patch(~p"/app/automation/automations/#{workflow.id}")}
                  phx-value-id={workflow.id}
                >
                  <.icon name="hero-pencil-square" />
                </.button>
                <.button
                  phx-click="delete_workflow"
                  phx-value-id={workflow.id}
                  data-confirm="Do you really want to delete this workflow?"
                >
                  <.icon name="hero-trash-solid" />
                </.button>
              </:row_after>
              <div class="whitespace-nowrap text-xl">
                {workflow.name}
              </div>
            </.list>
          </div>
        </section>
      </section>
    </.missing_deps_placeholder>
    """
  end

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
