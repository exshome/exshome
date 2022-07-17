defmodule ExshomeAutomation.Web.Live.ShowVariableModal do
  @moduledoc """
  Modal to show and edit variables.
  """
  alias Exshome.Variable
  use ExshomeWeb.Live.AppPage, dependencies: []

  @impl LiveView
  def mount(_params, %{"variable_id" => variable_id}, %Socket{} = socket) do
    {:ok, config} = Variable.get_by_id(variable_id)

    socket =
      socket
      |> assign(:config, config)
      |> put_error_message(nil)
      |> put_dependencies([{config.dependency, :variable}])

    {:ok, assign(socket, :config, config)}
  end

  @impl LiveView
  def handle_event("update_value", %{"variable" => value}, %Socket{} = socket) do
    {:noreply, set_value(socket, value)}
  end

  defp set_value(%Socket{} = socket, value) do
    case Variable.set_value(socket.assigns.config.dependency, value) do
      :ok -> put_error_message(socket, nil)
      {:error, error} -> put_error_message(socket, error)
    end
  end

  defp put_error_message(%Socket{} = socket, message), do: assign(socket, :error_message, message)
end
