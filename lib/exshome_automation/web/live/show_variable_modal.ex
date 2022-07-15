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
    socket =
      case validate_value(socket, value) do
        {:ok, socket} ->
          Variable.set_value!(socket.assigns.config.dependency, value)
          socket

        {:error, socket} ->
          socket
      end

    {:noreply, socket}
  end

  defp validate_value(%Socket{} = socket, value) do
    case Variable.validate_value(socket.assigns.config.dependency, value) do
      {:ok, _value} -> {:ok, put_error_message(socket, nil)}
      {:error, error} -> {:error, put_error_message(socket, error)}
    end
  end

  defp put_error_message(%Socket{} = socket, message), do: assign(socket, :error_message, message)
end
