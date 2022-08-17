defmodule ExshomeTest.SvgCanvasHelpers do
  @moduledoc """
  Helpers for testing svg canvas pages.
  """
  import ExUnit.Assertions
  import Phoenix.LiveViewTest

  defmodule Element do
    @moduledoc """
    Struct for svg elements.
    """

    defstruct [:id, :height, :width, :x, :y]

    @type t() :: %__MODULE__{
            id: String.t(),
            height: number(),
            width: number(),
            x: number(),
            y: number()
          }
  end

  @typep live_view() :: %{:__struct__ => Phoenix.LiveViewTest.View}

  @spec find_element_by_id(live_view(), String.t()) :: Element.t()
  def find_element_by_id(view, id) do
    [%Element{id: ^id} = svg_element] = find_elements(view, "##{id}")
    svg_element
  end

  @spec find_elements(live_view(), String.t()) :: list(Element.t())
  def find_elements(view, selector) do
    view
    |> render()
    |> Floki.find(selector)
    |> Enum.map(&to_element/1)
  end

  @spec get_viewbox(live_view()) :: %{x: number(), y: number(), height: number(), width: number()}
  def get_viewbox(view) do
    [{x, ""}, {y, ""}, {width, ""}, {height, ""}] =
      view
      |> render()
      |> Floki.attribute("#default-body", "viewbox")
      |> List.first()
      |> String.split(~r/\s+/)
      |> Enum.map(&Float.parse/1)

    %{x: x, y: y, height: height, width: width}
  end

  @spec render_dragend(live_view()) :: String.t()
  def render_dragend(view) do
    assert render_hook(view, "dragend", %{})
  end

  @spec resize(live_view(), %{height: number(), width: number()}) :: String.t()
  def resize(view, %{height: height, width: width}) do
    assert render_hook(view, "resize", %{height: height, width: width})
  end

  @spec select_element(live_view(), String.t()) :: String.t()
  def select_element(view, id) do
    %Element{x: x, y: y} = find_element_by_id(view, id)
    render_hook(view, "select", %{id: id, position: %{x: x, y: y}})
  end

  @spec to_element(Floki.html_tree()) :: Element.t()
  defp to_element(svg_element) do
    id =
      svg_element
      |> Floki.attribute("id")
      |> List.first()

    %Element{
      id: id,
      height: float_attribute(svg_element, "height"),
      width: float_attribute(svg_element, "width"),
      x: float_attribute(svg_element, "x"),
      y: float_attribute(svg_element, "y")
    }
  end

  @spec float_attribute(Floki.html_tree(), String.t()) :: number()
  defp float_attribute(svg_element, name) do
    {value, ""} =
      svg_element
      |> Floki.attribute(name)
      |> List.first()
      |> Float.parse()

    value
  end
end
