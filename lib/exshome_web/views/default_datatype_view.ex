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
    <label class="relative inline-block w-[4em] h-[2em] text-xl text-green-500/70 dark:text-green-600 select-none">
      <input name={@name} type="hidden" value="false" />
      <input class="w-0 h-0 opacity-0" name={@name} type="checkbox" value="true" checked={@value} />
      <span class="toggle absolute cursor-pointer bg-gray-300 dark:bg-gray-500 inset-0 rounded-full shadow-md" />
    </label>
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
