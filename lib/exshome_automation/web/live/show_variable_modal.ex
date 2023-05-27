defmodule ExshomeAutomation.Web.Live.ShowVariableModal do
  @moduledoc """
  Modal to show and edit variables.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Variable
  alias Exshome.Variable.VariableStateStream
  use ExshomeWeb.Live.AppPage, dependencies: []

  @impl LiveView
  def mount(_params, %{"variable_id" => variable_id} = data, %Socket{} = socket) do
    :ok = Dependency.subscribe({VariableStateStream, variable_id})
    {:ok, config} = Variable.get_by_id(variable_id)

    socket =
      socket
      |> assign(:config, config)
      |> assign(:rename, data["rename"] == "true")
      |> put_error_message(nil)
      |> put_dependencies([{config.dependency, :variable}])

    {:ok, assign(socket, :config, config)}
  end

  @impl LiveView
  def handle_event("update_value", %{"variable" => value}, %Socket{} = socket) do
    {:noreply, set_value(socket, value)}
  end

  def handle_event(
        "rename_variable",
        %{"value" => name},
        %Socket{assigns: %{config: %Variable{can_rename?: true}}} = socket
      ) do
    :ok = Variable.rename_by_id!(socket.assigns.config.id, name)
    {:noreply, socket}
  end

  defp set_value(%Socket{} = socket, value) do
    case Variable.set_value(socket.assigns.config.dependency, value) do
      :ok -> put_error_message(socket, nil)
      {:error, error} -> put_error_message(socket, error)
    end
  end

  defp put_error_message(%Socket{} = socket, message), do: assign(socket, :error_message, message)

  @impl AppPage
  def on_stream({{VariableStateStream, _id}, %Operation.Update{data: data}}, %Socket{} = socket) do
    assign(socket, :config, data)
  end
end
