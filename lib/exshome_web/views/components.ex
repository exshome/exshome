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
    assigns = LiveView.assign(assigns, :extra, extra)

    ~H"""
    <button
      class="p-2 m-2 rounded-xl
             bg-gray-200 dark:bg-gray-600 hover:bg-gray-300 dark:hover:bg-gray-500
             shadow-md shadow-gray-600 dark:shadow-gray-700"
      {@extra}
    >
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
      class="flex items-center flex-col"
      {@extra}
    >
      <%= for {field, data} <- @fields do %>
        <span>
          <label><%= field %></label>
          <%= render_field(f, field, data) %>
        </span>
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
    select(form, field, data[:allowed_values].(), class: "dark:bg-black rounded-lg")
  end

  defp render_field(form, field, :text, _data) do
    text_input(form, field, class: "bg-red-200")
  end
end
