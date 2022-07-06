defmodule ExshomeAutomation.Web.Live.Variables do
  @moduledoc """
  Variables page.
  """
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Web.Live.ShowVariableModal

  use ExshomeWeb.Live.AppPage,
    dependencies: [{VariableRegistry, :variables}],
    icon: "☑️"

  @impl LiveView
  def handle_event("show_variable", %{"id" => id}, socket) do
    {:noreply, open_modal(socket, ShowVariableModal, %{"variable_id" => id})}
  end
end
