defmodule ExshomeAutomation.Web.Live.Variables do
  @moduledoc """
  Variables page.
  """
  alias Exshome.Event
  alias Exshome.Variable
  alias Exshome.Variable.DynamicVariable
  alias Exshome.Variable.VariableStateEvent
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Web.Live.ShowVariableModal

  use ExshomeWeb.Live.AppPage,
    dependencies: [{VariableRegistry, :variables}],
    icon: "☑️"

  @impl LiveView
  def handle_event("show_variable", %{"id" => id}, %Socket{} = socket) do
    {:noreply, open_variable_modal(socket, id)}
  end

  @impl LiveView
  def handle_event("new_variable", %{"type" => type}, %Socket{} = socket) do
    type = Exshome.DataType.get_by_name(type)
    :ok = Event.subscribe(VariableStateEvent)
    :ok = DynamicVariable.create_variable!(type)
    {:noreply, socket}
  end

  @impl AppPage
  def on_app_event(
        %VariableStateEvent{type: :created, data: %Variable{id: id}},
        %Socket{} = socket
      ) do
    Event.unsubscribe(VariableStateEvent)
    open_variable_modal(socket, id)
  end

  def on_app_event(_, %Socket{} = socket), do: socket

  defp open_variable_modal(%Socket{} = socket, id) when is_binary(id) do
    open_modal(socket, ShowVariableModal, %{"variable_id" => id})
  end
end
