defmodule ExshomeWeb.DefaultDatatypeView do
  @moduledoc """
  Renders default datatypes.
  """
  alias Exshome.DataType.{Boolean, Integer, String}
  use ExshomeWeb.DataTypeView, [Boolean, Integer, String]

  @impl DataTypeView
  def render_value(assigns), do: ~H"<%= @value %>"

  @impl DataTypeView
  def render_input(%{type: Boolean} = assigns) do
    ~H"""
    <select name={@name} class={"#{default_input_styles()} min-w-[5em]"}>
      <%= for option <- [true, false] do %>
        <option value={"#{option}"} selected={@value == option}><%= option %></option>
      <% end %>
    </select>
    """
  end

  def render_input(%{type: Integer} = assigns) do
    ~H"""
    <input class={default_input_styles()} type="number" value={@value} name={@name} />
    """
  end

  def render_input(%{type: String} = assigns) do
    ~H"""
    <input class={default_input_styles()} type="text" value={@value} name={@name} />
    """
  end

  def default_input_styles do
    """
    rounded-xl bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 shadow-md p-2
    """
  end
end
