defmodule ExshomeWeb.DatatypeView do
  @moduledoc """
  Renders datatypes.
  """

  use Phoenix.Component
  alias Exshome.Datatype
  alias Phoenix.LiveView.Rendered

  @callback render_value(assigns :: map()) :: Rendered.t()
  @callback render_input(assigns :: map()) :: Rendered.t()

  @spec available_renderers() :: %{Datatype.t() => module()}
  def available_renderers, do: Map.fetch!(Exshome.Tag.tag_mapping(), __MODULE__)

  @spec datatype_value(assigns :: map()) :: Rendered.t()
  def datatype_value(%{type: type} = assigns) when is_atom(type) do
    renderer = Map.fetch!(available_renderers(), type)
    renderer.render_value(assigns)
  end

  attr :class, :string, default: "", doc: "extra component classes"
  attr :name, :string, doc: "name of the input"
  attr :type, :atom, doc: "type of a data"
  attr :value, :any, doc: "input value"
  attr :validations, :any, default: %{}, doc: "validate input value"

  def datatype_input(%{type: type} = assigns) when is_atom(type) do
    renderer = Map.fetch!(available_renderers(), type)

    renderer.render_input(assigns)
  end

  defmacro __using__(datatypes) do
    quote do
      import Exshome.Tag, only: [add_tag: 2]
      alias ExshomeWeb.DatatypeView
      import Phoenix.Component

      for type <- unquote(datatypes) do
        add_tag(DatatypeView, key: type)
      end

      use ExshomeWeb, :html

      @behaviour DatatypeView
    end
  end
end
