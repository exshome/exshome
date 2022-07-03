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
end
