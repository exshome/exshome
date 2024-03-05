defmodule ExshomeWeb.DatatypeComponent do
  @moduledoc """
  Renders datatypes.
  """

  use Phoenix.Component
  alias Exshome.Datatype
  alias Phoenix.LiveView.Rendered

  @spec available_renderers() :: %{Datatype.t() => module()}
  def available_renderers do
    Exshome.BehaviourMapping.custom_mapping!(Exshome.Mappings.DatatypeComponentsMapping)
  end

  @spec datatype_value(assigns :: map()) :: Rendered.t()
  def datatype_value(%{type: type} = assigns) when is_atom(type) do
    get_renderer!(type).render_value(assigns)
  end

  attr :class, :string, default: "", doc: "extra component classes"
  attr :name, :string, doc: "name of the input"
  attr :type, :atom, doc: "type of a data"
  attr :value, :any, doc: "input value"
  attr :validations, :any, default: %{}, doc: "validate input value"

  def datatype_input(%{type: type} = assigns) when is_atom(type) do
    get_renderer!(type).render_input(assigns)
  end

  @spec get_renderer!(Datatype.t()) :: module()
  defp get_renderer!(type), do: Map.fetch!(available_renderers(), type)
end
