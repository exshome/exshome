defmodule ExshomeWebTest.SvgCanvasTest do
  use ExshomeWeb.ConnCase, async: true
  import ExshomeTest.SvgCanvasHelpers

  @default_width 1000
  @default_height 2000

  describe "resize" do
    setup %{conn: conn} do
      view = render_automations(conn)
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
      render_hook(view, "move-background", %{pointer: %{x: -100, y: -100}})
      assert match?(%{x: 20.0, y: 20.0}, get_body_viewbox(view))
      render_hook(view, "move-background", %{pointer: %{x: -50, y: -50}})
      assert match?(%{x: 10.0, y: 10.0}, get_body_viewbox(view))
      render_dragend(view, %{x: 10, y: 10})

      select_background(view)
      render_hook(view, "move-background", %{pointer: %{x: -100, y: -100}})
      render_dragend(view, %{x: 10, y: 10})
      assert match?(%{x: 40.0, y: 40.0}, get_body_viewbox(view))
    end

    test "scroll-x", %{view: view} do
      select_element(view, "scroll-body-x-default")
      render_hook(view, "scroll-body-x", %{pointer: %{x: 60}})
      %{x: x, y: 0.0} = get_body_viewbox(view)
      assert_in_delta(x, 75.4, 0.1)
    end

    test "max scroll-x fits a page", %{view: view} do
      select_element(view, "scroll-body-x-default")
      render_hook(view, "scroll-body-x", %{pointer: %{x: @default_width}})
      [%{x: x, width: width}] = find_elements(view, "[data-drag='scroll-body-x']")
      assert width + x < @default_width
    end

    test "scroll-y", %{view: view} do
      select_element(view, "scroll-body-y-default")
      render_hook(view, "scroll-body-y", %{pointer: %{y: 60}})
      %{x: 0.0, y: y} = get_body_viewbox(view)
      assert_in_delta(y, 73.6, 0.1)
    end

    test "max scroll-y fits a page", %{view: view} do
      select_element(view, "scroll-body-y-default")
      render_hook(view, "scroll-body-y", %{pointer: %{y: @default_height}})
      [%{y: y, height: height}] = find_elements(view, "[data-drag='scroll-body-y']")
      assert height + y < @default_height
    end
  end

  describe "zoom" do
    setup %{conn: conn} do
      %{view: setup_page(conn)}
    end

    test "desktop", %{view: view} do
      render_hook(view, "zoom-desktop", %{pointer: %{x: 0, y: 0}, delta: -1})
      assert %{x: 0.0, y: 0.0, height: 500.0, width: 250.0} == get_body_viewbox(view)
      render_hook(view, "zoom-desktop", %{pointer: %{x: 50, y: 50}, delta: 1})
      assert %{x: 2.5, y: 2.5, height: 400, width: 200} == get_body_viewbox(view)
      render_hook(view, "zoom-desktop", %{pointer: %{x: 0, y: 0}, delta: -100})

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
  end

  describe "menu" do
    setup %{conn: conn} do
      %{view: setup_page(conn)}
    end

    test "close", %{view: view} do
      assert view |> element("#menu-data-default.hidden") |> has_element?()
      toggle_menu(view)
      refute view |> element("#menu-data-default.hidden") |> has_element?()
      view |> element("#menu-overlay-default") |> render_click()
      assert view |> element("#menu-data-default.hidden") |> has_element?()
    end

    test "toggle", %{view: view} do
      assert view |> element("#menu-data-default.hidden") |> has_element?()
      toggle_menu(view)
      refute view |> element("#menu-data-default.hidden") |> has_element?()
      toggle_menu(view)
      assert view |> element("#menu-data-default.hidden") |> has_element?()
    end
  end

  defp render_automations(conn) do
    live_with_dependencies(conn, ExshomeAutomation, :automations)
  end

  defp select_background(view) do
    select_element(view, "canvas-background-default")
  end

  defp setup_page(conn) do
    view = render_automations(conn)
    resize(view, %{width: @default_width, height: @default_height})
    view
  end

  defp zoom_mobile(view, original, current_touches) do
    render_hook(view, "zoom-mobile", %{
      original: original,
      current: current_touches
    })
  end
end
