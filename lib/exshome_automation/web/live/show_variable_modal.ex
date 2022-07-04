defmodule ExshomeAutomation.Web.Live.ShowVariableModal do
  @moduledoc """
  Modal to show and edit variables.
  """
  alias Exshome.Variable
  use ExshomeWeb.Live.AppPage, dependencies: []

  @impl LiveView
  def mount(_params, %{"variable_id" => variable_id}, %Socket{} = socket) do
    {:ok, config} = Variable.find_by_id(variable_id)

    socket =
      socket
      |> assign(:config, config)
      |> put_dependencies([{config.dependency, :variable}])

    {:ok, assign(socket, :config, config)}
  end

  @impl LiveView
  def handle_event("validate", _params, %Socket{} = socket) do
    {:noreply, socket}
  end

  @impl LiveView
  def handle_event("save", %{"variable" => value}, %Socket{} = socket) do
    Variable.set_value!(socket.assigns.config.dependency, String.to_integer(value))
    {:noreply, socket}
  end
end
