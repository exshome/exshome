defmodule ExshomeWeb.Live.SvgCanvas.ComponentMeta do
  @moduledoc """
  Collects metadata about the component.
  SvgCanvas uses it to generate HTML attributes.
  Browser part uses these attributes to work properly.
  """

  defstruct [
    :id,
    :type,
    :canvas_name
  ]

  @type t() :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          canvas_name: String.t()
        }

  def to_component_args(%__MODULE__{} = data) do
    [
      {:"data-svg-id", data.id},
      {:"data-svg-component", to_component(data)},
      {:"data-svg-type", data.type},
      {:"data-svg-name", data.canvas_name}
    ]
  end

  @spec menu_item_meta(type :: String.t(), canvas_name :: atom()) :: t()
  def menu_item_meta(type, canvas_name) do
    %__MODULE__{
      id: type,
      type: "menu-item",
      canvas_name: canvas_name
    }
  end

  @spec component_meta(id :: String.t(), canvas_name :: atom()) :: t()
  def component_meta(id, canvas_name) do
    %__MODULE__{
      id: id,
      type: "component",
      canvas_name: canvas_name
    }
  end

  @spec to_component(t()) :: String.t()
  def to_component(%__MODULE__{} = data) do
    "#{data.canvas_name}-#{data.type}-#{data.id}"
  end
end
