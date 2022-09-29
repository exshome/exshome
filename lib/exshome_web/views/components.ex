defmodule ExshomeWeb.Components do
  @moduledoc """
  Generic application components.
  """

  use Phoenix.HTML
  use Phoenix.Component, global_prefixes: ~w(phx-)
  import ExshomeWeb.ErrorHelpers

  attr :class, :string, default: "", doc: "custom button styles"
  attr :type, :string, default: "button", values: ["button", "submit"], doc: "button type"
  attr :rest, :global, doc: "extra button attributes"
  slot(:inner_block, requred: true, doc: "inner button content")

  def button(assigns) do
    ~H"""
    <button
      class={"p-2 m-1 rounded-xl
             bg-gray-200 dark:bg-gray-600 enabled:hover:bg-gray-300 enabled:dark:hover:bg-gray-500
             disabled:text-gray-300 disabled:dark:text-gray-500
             shadow-md shadow-gray-600 dark:shadow-gray-700 #{@class}"}
      type={@type}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  slot(:inner_block, requred: true, doc: "")

  def chip(assigns) do
    ~H"""
    <span class="inline-block bg-green-300/50 dark:bg-green-800/50 rounded-xl p-1 shadow-md">
      <%= render_slot(@inner_block) %>
    </span>
    """
  end

  attr :name, :string, required: true, doc: "form input name for select component"
  attr :values, :list, doc: "list of available values"
  slot(:label, required: true, doc: "label for a value")
  slot(:value, required: true, doc: "option value")

  def custom_select(assigns) do
    ~H"""
    <select
      class="p-3 w-full md:w-1/6 bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 rounded-xl shadow-lg dark:shadow-gray-700"
      name={@name}
    >
      <option :for={value <- @values} value={render_slot(@value, value)}>
        <%= render_slot(@label, value) %>
      </option>
    </select>
    """
  end

  attr :as, :atom, required: true
  attr :changeset, Ecto.Changeset, required: true, doc: "changeset to render a form"
  attr :rest, :global, doc: "extra form attributes"
  attr :fields, :list, doc: "list of form fields"

  def live_form(assigns) do
    ~H"""
    <.form
      :let={f}
      as={@as}
      for={@changeset}
      phx-change="validate"
      phx-submit="save"
      class="flex items-center flex-col max-h-full w-full overflow-x-hidden overflow-y-auto my-2"
      {@rest}
    >
      <%= for {field, data} <- @fields do %>
        <div class="p-2 w-full md:w-3/4">
          <label class="block font-bold"><%= field %></label>
          <%= render_field(f, field, data) %>
        </div>
        <%= error_tag(f, field) %>
      <% end %>
      <.button type="submit" phx-disable-with="Saving...">
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

  attr :rows, :list, required: true, doc: "list values"
  slot(:inner_block, required: true, doc: "list item content")
  slot(:row_after, doc: "content after each list item")
  slot(:row_before, doc: "content before each list item")

  def list(assigns) do
    ~H"""
    <ul class="mx-2 flex flex-col items-center justify-center">
      <li
        :for={row <- @rows}
        class="bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700
               shadow-md shadow-gray-600 dark:shadow-gray-700
               rounded-xl flex items-center justify-between
               py-4 px-2 m-2 w-full sm:w-3/4 md:w-1/2
               "
      >
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
    </ul>
    """
  end
end
