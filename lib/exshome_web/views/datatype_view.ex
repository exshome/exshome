defmodule ExshomeWeb.DataTypeView do
  @moduledoc """
  Renders datatypes.
  """

  alias Exshome.DataType
  alias Phoenix.LiveView
  alias Phoenix.LiveView.Rendered

  @callback render_value(assigns :: map()) :: Rendered.t()
  @callback render_input(assigns :: map()) :: Rendered.t()

  @spec available_renderers() :: %{DataType.t() => module()}
  def available_renderers, do: Map.fetch!(Exshome.Tag.tag_mapping(), __MODULE__)

  @spec datatype_value(assigns :: map()) :: Rendered.t()
  def datatype_value(%{type: type} = assigns) when is_atom(type) do
    renderer = Map.fetch!(available_renderers(), type)
    renderer.render_value(assigns)
  end

  @spec datatype_input(assigns :: map()) :: Rendered.t()
  def datatype_input(%{type: type} = assigns) when is_atom(type) do
    renderer = Map.fetch!(available_renderers(), type)

    assigns
    |> LiveView.assign_new(:validations, fn _ -> %{} end)
    |> renderer.render_input()
  end

  defmacro __using__(datatypes) do
    quote do
      import Exshome.Tag, only: [add_tag: 2]
      alias ExshomeWeb.DataTypeView
      alias Phoenix.LiveView
      import Phoenix.LiveView.Helpers

      for type <- unquote(datatypes) do
        add_tag(DataTypeView, key: type)
      end

      use ExshomeWeb, :view

      @behaviour DataTypeView
    end
  end
end
