defmodule ExshomeWebTest.SvgCanvasTest do
  use ExshomeWebTest.ConnCase, async: true

  alias Exshome.DataStream.Operation
  alias Exshome.Emitter
  alias ExshomeAutomation.Live.AutomationEditor
  alias ExshomeAutomation.Services.Workflow
  alias ExshomeAutomation.Streams.WorkflowStateStream
  alias ExshomeTest.TestRegistry

  import ExshomeTest.SvgCanvasHelpers

  @default_width 1000
  @default_height 2000

  describe "resize" do
    setup %{conn: conn} do
      view = render_automation_editor(conn)
      %{view: view}
    end

    test "square shape", %{view: view} do
      resize(view, %{height: 1000, width: 1000})
      assert get_body_viewbox(view) == %{x: 0, y: 0, height: 200, width: 200}
    end

    test "rectangular shape", %{view: view} do
      resize(view, %{height: 1000, width: 500})
      assert %{x: 0, y: 0, height: 200, width: 100} == get_body_viewbox(view)
      resize(view, %{height: 500, width: 1000})
      assert %{x: 0, y: 0, height: 100, width: 200} == get_body_viewbox(view)
    end
  end

  describe "move" do
    setup %{conn: conn} do
      %{view: setup_page(conn)}
    end

    test "background", %{view: view} do
      select_background(view)
      move_pointer(view, %{x: -100, y: -100}, "canvas")
      assert match?(%{x: 20.0, y: 20.0}, get_body_viewbox(view))
      move_pointer(view, %{x: -50, y: -50}, "canvas")
      assert match?(%{x: 10.0, y: 10.0}, get_body_viewbox(view))
      render_dragend(view, %{x: 10, y: 10})

      select_background(view)
      move_pointer(view, %{x: -100, y: -100}, "canvas")
      render_dragend(view, %{x: 10, y: 10})
      assert match?(%{x: 40.0, y: 40.0}, get_body_viewbox(view))
    end

    test "scroll-x", %{view: view} do
      select_component(view, "canvas-scroll-x")
      move_pointer(view, %{x: 60}, "canvas")
      %{x: x, y: y} = get_body_viewbox(view)
      assert_in_delta(y, 0.0, 0.1)
      assert_in_delta(x, 75.4, 0.1)
    end

    test "max scroll-x fits a page", %{view: view} do
      select_component(view, "canvas-scroll-x")
      move_pointer(view, %{x: @default_width}, "canvas")
      %{x: x, width: width} = find_component(view, "canvas-scroll-x")
      assert width + x < @default_width
    end

    test "scroll-y", %{view: view} do
      select_component(view, "canvas-scroll-y")
      move_pointer(view, %{y: 60}, "canvas")
      %{x: x, y: y} = get_body_viewbox(view)
      assert_in_delta(x, 0.0, 0.1)
      assert_in_delta(y, 73.6, 0.1)
    end

    test "max scroll-y fits a page", %{view: view} do
      select_component(view, "canvas-scroll-y")
      move_pointer(view, %{y: @default_height}, "canvas")
      %{y: y, height: height} = find_component(view, "canvas-scroll-y")
      assert height + y < @default_height
    end

    test "dragend works fine without selection", %{view: view} do
      render_dragend(view, %{x: @default_width, y: @default_width})
      render_dragend(view, %{x: @default_width, y: @default_width})
    end
  end

  describe "zoom" do
    setup %{conn: conn} do
      %{view: setup_page(conn)}
    end

    test "desktop", %{view: view} do
      render_hook(view, "canvas-zoom-desktop", %{
        pointer: %{x: 0, y: 0},
        delta: -1,
        name: "canvas"
      })

      assert %{x: 0.0, y: 0.0, height: 500.0, width: 250.0} == get_body_viewbox(view)

      render_hook(view, "canvas-zoom-desktop", %{
        pointer: %{x: 50, y: 50},
        delta: 1,
        name: "canvas"
      })

      assert %{x: 2.5, y: 2.5, height: 400, width: 200} == get_body_viewbox(view)

      render_hook(view, "canvas-zoom-desktop", %{
        pointer: %{x: 0, y: 0},
        delta: -100,
        name: "canvas"
      })

      assert %{x: 0, y: 0, height: @default_height, width: @default_width} ==
               get_body_viewbox(view)
    end

    test "mobile zoom-out", %{view: view} do
      original = %{position: %{x: 0, y: 0}, touches: [%{x: 0, y: 0}, %{x: 100, y: 100}]}

      zoom_mobile(view, original, [%{x: 40, y: 40}, %{x: 60, y: 60}])

      assert %{x: 0, y: 0, height: @default_height, width: @default_width} ==
               get_body_viewbox(view)
    end

    test "mobile zoom-out, same touches", %{view: view} do
      original = %{position: %{x: 0, y: 0}, touches: [%{x: 40, y: 40}, %{x: 60, y: 60}]}

      zoom_mobile(view, original, [%{x: 50, y: 50}, %{x: 50, y: 50}])

      assert %{x: 0, y: 0, height: @default_height, width: @default_width} ==
               get_body_viewbox(view)
    end

    test "mobile move", %{view: view} do
      original = %{position: %{x: 10, y: 10}, touches: [%{x: 40, y: 40}, %{x: 60, y: 60}]}

      zoom_mobile(view, original, [%{x: 40, y: 40}, %{x: 60, y: 60}])

      assert %{x: 10, y: 10, height: 400, width: 200} == get_body_viewbox(view)

      zoom_mobile(view, original, [%{x: 50, y: 50}, %{x: 70, y: 70}])

      assert %{x: 8, y: 8, height: 400, width: 200} == get_body_viewbox(view)

      zoom_mobile(view, original, [%{x: 30, y: 30}, %{x: 50, y: 50}])

      assert %{x: 12, y: 12, height: 400, width: 200} == get_body_viewbox(view)
    end

    test "mobile zoom-in", %{view: view} do
      original = %{position: %{x: 0, y: 0}, touches: [%{x: 40, y: 40}, %{x: 60, y: 60}]}

      zoom_mobile(view, original, [%{x: 30, y: 30}, %{x: 70, y: 70}])

      assert %{x: 5, y: 5, height: 200, width: 100} == get_body_viewbox(view)
    end

    test "mobile zoom-in, same touches", %{view: view} do
      original = %{position: %{x: 0, y: 0}, touches: [%{x: 50, y: 50}, %{x: 50, y: 50}]}

      zoom_mobile(view, original, [%{x: 40, y: 40}, %{x: 60, y: 60}])

      assert %{x: 5, y: 5, height: 200, width: 100} == get_body_viewbox(view)
    end

    test "zoom-in button", %{view: view} do
      initial_zoom = get_zoom_value(view)

      view
      |> element("[phx-click^='canvas-zoom-in']")
      |> render_click()

      assert initial_zoom < get_zoom_value(view)
    end

    test "zoom-out button", %{view: view} do
      initial_zoom = get_zoom_value(view)

      view
      |> element("[phx-click^='canvas-zoom-out']")
      |> render_click()

      assert initial_zoom > get_zoom_value(view)
    end

    test "zoom slider", %{view: view} do
      initial_value = get_zoom_value(view)

      new_value =
        1..10
        |> Enum.reject(&(&1 == initial_value))
        |> Enum.random()

      set_zoom_value(view, new_value)
      assert new_value == get_zoom_value(view)
    end
  end

  describe "menu" do
    setup %{conn: conn} do
      %{view: setup_page(conn)}
    end

    test "close", %{view: view} do
      assert view |> element("#menu-data-canvas.hidden") |> has_element?()
      toggle_menu(view)
      refute view |> element("#menu-data-canvas.hidden") |> has_element?()
      view |> element("#menu-overlay-canvas") |> render_click()
      assert view |> element("#menu-data-canvas.hidden") |> has_element?()
    end

    test "toggle", %{view: view} do
      assert view |> element("#menu-data-canvas.hidden") |> has_element?()
      toggle_menu(view)
      refute view |> element("#menu-data-canvas.hidden") |> has_element?()
      toggle_menu(view)
      assert view |> element("#menu-data-canvas.hidden") |> has_element?()
    end

    test "create item", %{view: view} do
      assert count_elements(view) == 0
      :ok = generate_random_components(view, 5)
      assert count_elements(view) == 5
    end
  end

  defp count_elements(view) do
    view
    |> find_elements("[data-svg-component^='canvas-component-']")
    |> length()
  end

  defp render_automation_editor(conn) do
    TestRegistry.start_dynamic_supervisor(Workflow.WorkflowSupervisor)
    :ok = Emitter.subscribe(WorkflowStateStream)
    :ok = Workflow.create!()

    assert_receive_stream(
      {WorkflowStateStream, %Operation.Insert{data: %Workflow{id: workflow_id}}}
    )

    start_app_page_dependencies(AutomationEditor)
    {:ok, view, _html} = live(conn, "/app/automation/automations/#{workflow_id}")
    view
  end

  defp select_background(view) do
    select_component(view, "canvas-background-canvas-background")
  end

  defp setup_page(conn) do
    view = render_automation_editor(conn)
    resize(view, %{width: @default_width, height: @default_height})
    view
  end

  defp zoom_mobile(view, original, current_touches) do
    render_hook(view, "canvas-zoom-mobile", %{
      original: original,
      current: current_touches,
      name: "canvas"
    })
  end
end
