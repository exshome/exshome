defmodule ExshomeAutomation.Live.ShowVariableModal do
  @moduledoc """
  Modal to show and edit variables.
  """

  alias Exshome.DataStream.Operation
  alias Exshome.Dependency.NotReady
  alias Exshome.Emitter
  alias Exshome.Variable
  alias Exshome.Variable.VariableConfig
  alias Exshome.Variable.VariableStateStream
  use ExshomeWeb.Live.AppPage, dependencies: []

  @impl LiveView
  def render(%{config: NotReady} = assigns), do: ~H"There is no such variable"

  def render(assigns) do
    ~H"""
    <.missing_deps_placeholder deps={@deps}>
      <section class="flex flex-col items-center justify-center h-full">
        <.live_component
          module={ExshomeWeb.Live.RenameComponent}
          id="rename_variable"
          value={@config.name}
          can_rename?={@config.can_rename?}
        />
        <div class="text-xs mb-5">
          <.chip>
            {Exshome.Datatype.icon(@config.type)}
            {Exshome.Datatype.name(@config.type)}
          </.chip>
          <%= if @config.readonly? do %>
            <.chip>
              🔒 readonly
            </.chip>
          <% end %>
        </div>

        <%= if @config.not_ready_reason do %>
          <div class="text-md text-red-400/80">
            {@config.not_ready_reason}
          </div>
        <% else %>
          <%= if !@config.readonly? do %>
            <form class="w-full md:w-3/4 flex flex-col items-center" phx-change="update_value">
              <.datatype_input
                type={@config.type}
                value={@deps.variable}
                validations={@config.validations}
                name="variable"
              />
              <%= if @error_message do %>
                <div type="error" class="text-red-300">{@error_message}</div>
              <% end %>
            </form>
          <% end %>
          <div class="text-md [word-break:break-word] font-black text-center">
            <.datatype_value type={@config.type} value={@deps.variable} />
          </div>
        <% end %>
      </section>
    </.missing_deps_placeholder>
    """
  end

  @impl LiveView
  def mount(_params, %{"id" => variable_id}, %Socket{} = socket) do
    :ok = Emitter.subscribe({VariableStateStream, variable_id})
    {:ok, config} = Variable.get_by_id(variable_id)

    socket =
      socket
      |> assign(:config, config)
      |> put_error_message(nil)
      |> put_dependencies([{config.service_id, :variable}])

    {:ok, socket}
  end

  @impl LiveView
  def handle_event("update_value", %{"variable" => value}, %Socket{} = socket) do
    {:noreply, set_value(socket, value)}
  end

  def handle_event(
        "rename_variable",
        %{"new_name" => name},
        %Socket{assigns: %{config: %VariableConfig{can_rename?: true}}} = socket
      ) do
    :ok = Variable.rename_by_id!(socket.assigns.config.id, name)
    {:noreply, socket}
  end

  defp set_value(%Socket{} = socket, value) do
    case Variable.set_value(socket.assigns.config.service_id, value) do
      :ok -> put_error_message(socket, nil)
      {:error, error} -> put_error_message(socket, error)
    end
  end

  defp put_error_message(%Socket{} = socket, message), do: assign(socket, :error_message, message)

  @impl AppPage
  def on_stream({{VariableStateStream, _id}, %Operation.Update{data: data}}, %Socket{} = socket) do
    assign(socket, :config, data)
  end

  def on_stream({{VariableStateStream, _id}, %Operation.Delete{}}, %Socket{} = socket) do
    assign(socket, :config, NotReady)
  end
end
