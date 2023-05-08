defmodule ExshomeTest.SvgCanvasHelpers do
  @moduledoc """
  Helpers for testing svg canvas pages.
  """
  import ExUnit.Assertions
  import Phoenix.LiveViewTest
  import ExshomeTest.LiveViewHelpers

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

  @typep live_view_t() :: %{:__struct__ => Phoenix.LiveViewTest.View, :proxy => any()}
  @typep position_t() :: %{x: number(), y: number()}
  @typep viewbox_t() :: %{x: number(), y: number(), height: number(), width: number()}

  @spec compute_pointer_position(live_view_t(), position_t()) :: position_t()
  def compute_pointer_position(view, %{x: x, y: y}) do
    rate = get_zoom_rate(view)
    %{x: x * rate.x, y: y * rate.y}
  end

  @spec find_element_by_id(live_view_t(), String.t()) :: Element.t()
  def find_element_by_id(view, id) do
    [%Element{id: ^id} = svg_element] = find_elements(view, "##{id}")
    svg_element
  end

  @spec find_elements(live_view_t(), String.t()) :: list(Element.t())
  def find_elements(view, selector) do
    view
    |> render()
    |> Floki.find(selector)
    |> Enum.map(&to_element/1)
  end

  @spec get_body_viewbox(live_view_t()) :: viewbox_t()
  def get_body_viewbox(view) do
    get_viewbox(view, "#default-body")
  end

  @spec get_viewbox(live_view_t(), String.t()) :: viewbox_t()
  def get_viewbox(view, id) do
    [{x, ""}, {y, ""}, {width, ""}, {height, ""}] =
      view
      |> render()
      |> Floki.attribute(id, "viewbox")
      |> List.first()
      |> String.split(~r/\s+/)
      |> Enum.map(&Float.parse/1)

    %{x: x, y: y, height: height, width: width}
  end

  defp get_zoom_rate(view) do
    %{height: body_height, width: body_width} = get_body_viewbox(view)
    %{height: canvas_height, width: canvas_width} = get_viewbox(view, "#default-screen")
    %{x: canvas_width / body_width, y: canvas_height / body_height}
  end

  @spec render_create_element(live_view_t(), String.t(), position_t()) :: any()
  def render_create_element(view, id, position) do
    select_element(view, id)
    render_hook(view, "create", %{pointer: position})
  end

  @spec render_dragend(live_view_t(), position :: position_t()) :: String.t()
  def render_dragend(view, position) do
    assert render_hook(view, "dragend", %{pointer: compute_pointer_position(view, position)})
  end

  @spec render_move(live_view_t(), String.t(), position_t()) :: any()
  def render_move(view, id, position) do
    select_element(view, id)
    assert_push_event(view, "move-to-foreground", %{id: ^id, parent: "default-body"})
    render_hook(view, "move", %{pointer: compute_pointer_position(view, position)})
  end

  @spec resize(live_view_t(), %{height: number(), width: number()}) :: String.t()
  def resize(view, %{height: height, width: width}) do
    assert render_hook(view, "resize", %{height: height, width: width})
  end

  @spec select_element(live_view_t(), String.t()) :: String.t()
  def select_element(view, id) do
    %Element{x: x, y: y} = find_element_by_id(view, id)

    position = %{x: x, y: y}

    render_hook(view, "select", %{
      id: id,
      offset: %{x: 0, y: 0},
      position: position,
      pointer: compute_pointer_position(view, position)
    })
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

  @spec toggle_menu(live_view_t()) :: :ok
  def toggle_menu(view) do
    view
    |> element("[phx-click^='menu-toggle-']")
    |> render_click()

    :ok
  end

  @spec translate_screen_to_canvas(live_view_t(), position_t()) :: position_t()
  def translate_screen_to_canvas(view, %{x: x, y: y}) do
    rate = get_zoom_rate(view)
    %{x: x / rate.x, y: y / rate.y}
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

  @spec get_zoom_value(live_view_t()) :: number()
  def get_zoom_value(view) do
    view
    |> get_value("[phx-change^='set-zoom-'] input")
    |> String.to_integer()
  end

  @spec set_zoom_value(live_view_t(), number()) :: String.t()
  def set_zoom_value(view, value) do
    view
    |> element("[phx-change^='set-zoom-']")
    |> render_change(%{value: value})
  end
end
