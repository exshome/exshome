defmodule ExshomeWeb.Components do
  @moduledoc """
  Generic application components.
  """

  alias Phoenix.LiveView
  use Phoenix.HTML
  import Phoenix.LiveView.Helpers
  import ExshomeWeb.ErrorHelpers

  def button(assigns) do
    extra = assigns_to_attributes(assigns, [:class])
    extra_classes = assigns[:class] || ""
    assigns = LiveView.assign(assigns, extra: extra, extra_classes: extra_classes)

    ~H"""
    <button class={"p-2 m-1 rounded-xl
             bg-gray-200 dark:bg-gray-600 enabled:hover:bg-gray-300 enabled:dark:hover:bg-gray-500
             disabled:text-gray-300 disabled:dark:text-gray-500
             shadow-md shadow-gray-600 dark:shadow-gray-700 #{@extra_classes}"} {@extra}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  def live_form(assigns) do
    extra = assigns_to_attributes(assigns, [:changeset, :fields])
    assigns = LiveView.assign(assigns, :extra, extra)

    ~H"""
    <.form
      let={f}
      for={@changeset}
      phx-change="validate"
      phx-submit="save"
      class="flex items-center flex-col max-h-full w-full overflow-x-hidden overflow-y-auto my-2"
      {@extra}
    >
      <%= for {field, data} <- @fields do %>
        <div class="p-2 w-full md:w-3/4">
          <label class="block font-bold"><%= field %></label>
          <%= render_field(f, field, data) %>
        </div>
        <%= error_tag(f, field) %>
      <% end %>
      <.button type="submit" phx_disable_with="Saving...">
        Save
      </.button>
    </.form>
    """
  end

  defp render_field(form, field, data) when is_atom(field) do
    type = if data[:allowed_values], do: :select, else: :text
    render_field(form, field, type, data)
  end

  defp render_field(form, field, :select, data) do
    select(form, field, data[:allowed_values].(),
      class: "w-full p-2 bg-gray-100 dark:bg-gray-800 rounded-lg shadow-md dark:shadow-gray-700"
    )
  end

  defp render_field(form, field, :text, _data) do
    text_input(form, field,
      class: "w-full p-2 rounded-lg bg-gray-100 dark:bg-gray-800 shadow-md dark:shadow-gray-700"
    )
  end

  def list(assigns) do
    assigns =
      assigns
      |> LiveView.assign_new(:row_before, fn -> [] end)
      |> LiveView.assign_new(:row_after, fn -> [] end)

    ~H"""
    <ul class="mx-2 flex flex-col items-center justify-center">
      <%= for row <- @rows do %>
        <li class="bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700
               shadow-md shadow-gray-600 dark:shadow-gray-700
               rounded-xl flex items-center justify-between
               py-4 px-2 m-2 w-full sm:w-3/4 md:w-1/2
               ">
          <div>
            <%= for row_before <- @row_before do %>
              <%= render_slot(row_before, row) %>
            <% end %>
          </div>
          <div class="flex flex-col flex-grow pl-2 text-left justify-center overflow-x-auto overflow-y-hidden">
            <%= render_slot(@inner_block, row) %>
          </div>
          <div class="pl-1 flex flex-row items-center justify-center">
            <%= for row_after <- @row_after do %>
              <%= render_slot(row_after, row) %>
            <% end %>
          </div>
        </li>
      <% end %>
    </ul>
    """
  end
end
