defmodule ExshomeAutomation.Web.Live.Variables do
  @moduledoc """
  Variables page.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Variable
  alias Exshome.Variable.VariableStateStream
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Variables.DynamicVariable
  alias ExshomeAutomation.Web.Live.ShowVariableModal

  use ExshomeWeb.Live.AppPage,
    dependencies: [{VariableRegistry, :variables}],
    icon: "hero-variable-mini"

  @impl LiveView
  def handle_event("show_variable", %{"id" => id}, %Socket{} = socket) do
    {:noreply, open_variable_modal(socket, id)}
  end

  @impl LiveView
  def handle_event("new_variable", %{"type" => type}, %Socket{} = socket) do
    type = Exshome.Datatype.get_by_name(type)
    :ok = Dependency.subscribe(VariableStateStream)
    :ok = DynamicVariable.create_variable!(type)
    {:noreply, socket}
  end

  def handle_event("delete_variable", %{"id" => id}, %Socket{} = socket) do
    :ok = Variable.delete_by_id!(id)
    {:noreply, socket}
  end

  @impl AppPage
  def on_stream(
        {VariableStateStream, %Operation.Insert{data: %Variable{id: id}}},
        %Socket{} = socket
      ) do
    Dependency.unsubscribe(VariableStateStream)
    open_variable_modal(socket, id, %{"rename" => "true"})
  end

  def on_stream(_, %Socket{} = socket), do: socket

  defp open_variable_modal(%Socket{} = socket, id, params \\ %{}) when is_binary(id) do
    open_modal(socket, ShowVariableModal, Map.merge(params, %{"variable_id" => id}))
  end
end
