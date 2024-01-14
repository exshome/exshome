defmodule ExshomeAutomation.Live.Variables do
  @moduledoc """
  Variables page.
  """
  alias Exshome.DataStream.Operation
  alias Exshome.Dependency
  alias Exshome.Variable
  alias Exshome.Variable.VariableStateStream
  alias ExshomeAutomation.Services.VariableRegistry
  alias ExshomeAutomation.Variables.DynamicVariable

  use ExshomeWeb.Live.AppPage,
    dependencies: [{VariableRegistry, :variables}]

  @impl LiveView
  def render(assigns) do
    ~H"""
    <.missing_deps_placeholder deps={@deps}>
      <section class="h-full max-h-full w-full p-4 flex flex-col overflow-hidden">
        <form class="mb-3 w-full flex items-center justify-center" phx-submit="new-variable">
          <.custom_select name="type" values={Enum.sort(Exshome.Datatype.available_types())}>
            <:value :let={type}><%= Exshome.Datatype.name(type) %></:value>
            <:label :let={type}>
              <%= Exshome.Datatype.icon(type) %>
              <%= Exshome.Datatype.name(type) %>
            </:label>
          </.custom_select>
          <.button type="submit" phx-disable-with="Creating..." class="whitespace-nowrap">
            New Variable
          </.button>
        </form>
        <section class="flex-grow h-full flex items-center overflow-auto">
          <div class="w-full max-h-full">
            <%= for {group, variables} <- @deps.variables |> Map.values() |> Enum.group_by(& &1.group) |> Enum.sort_by(&elem(&1, 0)) do %>
              <h2 class="text-4xl text-center mt-5 first:mt-0"><%= group %></h2>
              <.list :let={variable} rows={Enum.sort_by(variables, & &1.dependency)}>
                <:row_before :let={variable}>
                  <%= if variable.not_ready_reason do %>
                    <.icon name="hero-exclamation-triangle-solid" class="text-orange-400 p-3" />
                  <% else %>
                    <.icon name="hero-check-circle-solid" class="text-green-700 p-3" />
                  <% end %>
                </:row_before>
                <:row_after :let={variable}>
                  <.button phx-click="edit-variable" phx-value-id={variable.id}>
                    <.icon name="hero-pencil-square" />
                  </.button>
                  <%= if variable.can_delete? do %>
                    <.button
                      phx-click="delete-variable"
                      phx-value-id={variable.id}
                      data-confirm="Do you really want to delete this variable?"
                    >
                      <.icon name="hero-trash-solid" />
                    </.button>
                  <% end %>
                </:row_after>
                <div class="whitespace-nowrap text-xl">
                  <%= variable.name %>
                </div>
                <div class="text-xs whitespace-nowrap">
                  <.chip>
                    <%= Exshome.Datatype.icon(variable.type) %>
                    <%= Exshome.Datatype.name(variable.type) %>
                  </.chip>
                  <%= if variable.readonly? do %>
                    <.chip>
                      🔒 readonly
                    </.chip>
                  <% end %>
                </div>
                <div class="whitespace-nowrap text-red-400/80">
                  <%= variable.not_ready_reason %>
                </div>
              </.list>
            <% end %>
          </div>
        </section>
      </section>

      <.modal
        :if={@live_action == :show}
        id="show-variable"
        show
        on_cancel={JS.patch(~p"/app/automation/variables")}
      >
        <%= live_render(@socket, ExshomeAutomation.Live.ShowVariableModal,
          id: "modal-data",
          session: @modal_params
        ) %>
      </.modal>
    </.missing_deps_placeholder>
    """
  end

  @impl LiveView
  def handle_params(%{"id" => _id} = params, _uri, %Socket{} = socket) do
    {:noreply, assign(socket, modal_params: params)}
  end

  def handle_params(_, _, %Socket{} = socket), do: {:noreply, socket}

  @impl LiveView
  def handle_event("new-variable", %{"type" => type}, %Socket{} = socket) do
    type = Exshome.Datatype.get_by_name(type)
    :ok = Dependency.subscribe(VariableStateStream)
    :ok = DynamicVariable.create_variable!(type)
    {:noreply, socket}
  end

  def handle_event("delete-variable", %{"id" => id}, %Socket{} = socket) do
    :ok = Variable.delete_by_id!(id)
    {:noreply, socket}
  end

  def handle_event("edit-variable", %{"id" => id}, socket) do
    {:noreply, open_modal(socket, id)}
  end

  @impl AppPage
  def on_stream(
        {VariableStateStream, %Operation.Insert{data: %Variable{id: id}}},
        %Socket{} = socket
      ) do
    Dependency.unsubscribe(VariableStateStream)
    open_modal(socket, id)
  end

  def on_stream(_, %Socket{} = socket), do: socket

  defp open_modal(socket, id), do: push_patch(socket, to: ~p"/app/automation/variables/#{id}")
end
