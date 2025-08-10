defmodule ExshomeTest.SvgCanvasHelpers do
  @moduledoc """
  Helpers for testing svg canvas pages.
  """
  alias Exshome.DataStream.Operation
  alias ExshomeAutomation.Streams.EditorStream

  import ExUnit.Assertions
  import Phoenix.LiveViewTest
  import ExshomeTest.LiveViewHelpers
  import ExshomeTest.TestHelpers

  defmodule Element do
    @moduledoc """
    Struct for svg elements.
    """

    defstruct [:id, :canvas_name, :type, :component, :height, :width, :x, :y]

    @type t() :: %__MODULE__{
            id: String.t(),
            canvas_name: String.t(),
            type: String.t(),
            component: String.t(),
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

  @spec find_component(live_view_t(), String.t()) :: Element.t()
  def find_component(view, component) do
    [%Element{component: ^component} = svg_element] =
      find_elements(view, "[data-svg-component=#{component}]")

    svg_element
  end

  @spec find_elements(live_view_t(), String.t()) :: list(Element.t())
  def find_elements(view, selector) do
    view
    |> render()
    |> Floki.parse_fragment!()
    |> Floki.find(selector)
    |> Enum.map(&to_element/1)
  end

  @spec get_body_viewbox(live_view_t()) :: viewbox_t()
  def get_body_viewbox(view) do
    get_viewbox(view, "#canvas-body")
  end

  @spec get_viewbox(live_view_t(), String.t()) :: viewbox_t()
  def get_viewbox(view, id) do
    [{x, ""}, {y, ""}, {width, ""}, {height, ""}] =
      view
      |> render()
      |> Floki.parse_fragment!()
      |> Floki.attribute(id, "viewbox")
      |> List.first()
      |> String.split(~r/\s+/)
      |> Enum.map(&Float.parse/1)

    %{x: x, y: y, height: height, width: width}
  end

  defp get_zoom_rate(view) do
    %{height: body_height, width: body_width} = get_body_viewbox(view)
    %{height: canvas_height, width: canvas_width} = get_viewbox(view, "#canvas-screen")
    %{x: canvas_width / body_width, y: canvas_height / body_height}
  end

  @spec render_create_element(live_view_t(), String.t(), position_t()) :: any()
  def render_create_element(view, component, position) do
    %Element{} = element = find_component(view, component)
    select_element(view, element)
    move_pointer(view, position, element.canvas_name)
  end

  @spec render_dragend(live_view_t(), position :: position_t()) :: String.t()
  def render_dragend(view, position) do
    assert render_hook(view, "canvas-dragend", %{
             pointer: compute_pointer_position(view, position),
             name: "canvas"
           })
  end

  @spec render_move(live_view_t(), String.t(), position_t()) :: any()
  def render_move(view, component, position) do
    select_component(view, component)
    assert_push_event(view, "move-to-foreground", %{component: ^component})

    move_pointer(view, compute_pointer_position(view, position), "canvas")
  end

  @spec resize(live_view_t(), %{height: number(), width: number()}) :: String.t()
  def resize(view, %{height: height, width: width}) do
    assert render_hook(view, "canvas-resize", %{height: height, width: width, name: "canvas"})
  end

  @spec select_element(live_view_t(), Element.t()) :: String.t()
  def select_element(view, %Element{} = element) do
    position = %{x: element.x, y: element.y}

    render_hook(view, "canvas-select", %{
      id: element.id,
      type: element.type,
      offset: %{x: 0, y: 0},
      position: position,
      pointer: compute_pointer_position(view, position),
      name: element.canvas_name
    })
  end

  @spec select_component(live_view_t(), String.t()) :: String.t()
  def select_component(view, component) do
    %Element{} = element = find_component(view, component)
    select_element(view, element)
  end

  @spec move_pointer(live_view_t(), position_t(), canvas_name :: String.t()) :: any()
  def move_pointer(view, position, canvas_name) do
    render_hook(view, "canvas-move", %{pointer: position, name: canvas_name})
  end

  @spec to_element(Floki.html_tree()) :: Element.t()
  defp to_element(svg_element) do
    %Element{
      id: string_attribute(svg_element, "data-svg-id"),
      component: string_attribute(svg_element, "data-svg-component"),
      canvas_name: string_attribute(svg_element, "data-svg-name"),
      type: string_attribute(svg_element, "data-svg-type"),
      height: float_attribute(svg_element, "height"),
      width: float_attribute(svg_element, "width"),
      x: float_attribute(svg_element, "x"),
      y: float_attribute(svg_element, "y")
    }
  end

  @spec toggle_menu(live_view_t()) :: :ok
  def toggle_menu(view) do
    view
    |> element("[phx-click^='canvas-menu-toggle']")
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
      |> string_attribute(name)
      |> Float.parse()

    value
  end

  @spec string_attribute(Floki.html_tree(), String.t()) :: String.t()
  defp string_attribute(svg_element, name) do
    svg_element
    |> Floki.attribute(name)
    |> List.first()
  end

  @spec get_zoom_value(live_view_t()) :: number()
  def get_zoom_value(view) do
    view
    |> get_value("[phx-change^='canvas-set-zoom'] input")
    |> String.to_integer()
  end

  @spec set_zoom_value(live_view_t(), number()) :: String.t()
  def set_zoom_value(view, value) do
    view
    |> element("[phx-change^='canvas-set-zoom']")
    |> render_change(%{zoom: value, name: "canvas"})
  end

  @spec create_component(live_view_t(), String.t(), position_t()) :: any()
  def create_component(view, component, position) do
    :ok = toggle_menu(view)
    render_create_element(view, component, position)
  end

  @spec generate_random_components(live_view_t(), number()) :: :ok
  def generate_random_components(view, amount) do
    :ok = toggle_menu(view)

    components =
      view |> find_elements("[data-svg-component^=canvas-menu-item-]") |> Enum.map(& &1.component)

    :ok = toggle_menu(view)

    for _ <- 1..amount do
      position = %{x: 0, y: 0}
      create_component(view, Enum.random(components), position)
      assert_receive_app_page_stream({{EditorStream, _}, %Operation.Insert{}})
    end

    :ok
  end
end
