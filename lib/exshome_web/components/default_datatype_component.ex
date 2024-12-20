defmodule ExshomeWeb.DefaultDatatypeComponent do
  @moduledoc """
  Renders default datatypes.
  """

  alias Exshome.Behaviours.DatatypeComponentBehaviour
  alias Exshome.Datatype.{Boolean, Integer, String, Unknown}
  import Phoenix.Component

  @behaviour DatatypeComponentBehaviour

  @impl DatatypeComponentBehaviour
  def datatypes, do: MapSet.new([Boolean, Integer, String, Unknown])

  @impl DatatypeComponentBehaviour
  def render_value(assigns), do: ~H"{@value}"

  @impl DatatypeComponentBehaviour
  def render_input(%{type: Boolean} = assigns) do
    ~H"""
    <label class="relative inline-block w-[4em] h-[2em] text-xl text-green-500/70 dark:text-green-600 select-none">
      <input name={@name} type="hidden" value="false" />
      <input class="w-0 h-0 opacity-0" name={@name} type="checkbox" value="true" checked={@value} />
      <span class="toggle absolute cursor-pointer bg-gray-300 dark:bg-gray-500 inset-0 rounded-full shadow-md" />
    </label>
    """
  end

  def render_input(%{type: Integer, validations: %{min: _, max: _}} = assigns) do
    ~H"""
    <input
      class="w-full my-2 h-[1em] rounded-full text-green-800 dark:text-green-700 bg-green-600 dark:bg-green-800 shadow-md dark:shadow-gray-600"
      type="range"
      min={@validations[:min]}
      max={@validations[:max]}
      value={@value}
      name={@name}
    />
    """
  end

  def render_input(%{type: Integer, validations: validations} = assigns) do
    extra_attributes =
      for attr <- [:min, :max], value = Map.get(validations, attr), do: {attr, value}

    assigns = assign(assigns, :extra_attributes, extra_attributes)

    ~H"""
    <input
      class={"#{default_input_styles()} #{@class}"}
      type="number"
      value={@value}
      name={@name}
      {@extra_attributes}
    />
    """
  end

  def render_input(%{type: String} = assigns) do
    ~H"""
    <input class={"#{default_input_styles()} #{@class}"} type="text" value={@value} name={@name} />
    """
  end

  def default_input_styles do
    """
    rounded-xl bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 shadow-md p-2
    """
  end
end
