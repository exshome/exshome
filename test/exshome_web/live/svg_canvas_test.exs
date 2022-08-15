defmodule ExshomeWebTest.SvgCanvasTest do
  use ExshomeWeb.ConnCase, async: true

  @default_width 100
  @default_height 100

  describe "resize" do
    setup %{conn: conn} do
      view = render_automations(conn)
      %{view: view}
    end

    test "square shape", %{view: view} do
      resize(view, %{height: 1000, width: 1000})
      assert get_viewbox(view) == %{x: 0, y: 0, height: 200, width: 200}
    end

    test "rectangular shape", %{view: view} do
      resize(view, %{height: 1000, width: 500})
      assert %{x: 0, y: 0, height: 200, width: 100} == get_viewbox(view)
      resize(view, %{height: 500, width: 1000})
      assert %{x: 0, y: 0, height: 100, width: 200} == get_viewbox(view)
    end
  end

  describe "move" do
    setup %{conn: conn} do
      %{view: setup_page(conn)}
    end

    test "background", %{view: view} do
      select_background(view)
      render_hook(view, "move-background", %{x: -100, y: -100})
      assert match?(%{x: 20.0, y: 20.0}, get_viewbox(view))
      render_hook(view, "move-background", %{x: -50, y: -50})
      assert match?(%{x: 10.0, y: 10.0}, get_viewbox(view))
      render_dragend(view)

      select_background(view)
      render_hook(view, "move-background", %{x: -100, y: -100})
      render_dragend(view)
      assert match?(%{x: 32.0, y: 32.0}, get_viewbox(view))
    end

    test "scroll-x", %{view: view} do
      render_hook(view, "scroll-body-x", %{x: 100})
      assert match?(%{x: 480.0, y: 0.0}, get_viewbox(view))
    end

    test "scroll-y", %{view: view} do
      render_hook(view, "scroll-body-y", %{y: 100})
      assert match?(%{x: 0.0, y: 480.0}, get_viewbox(view))
    end
  end

  describe "zoom" do
    setup %{conn: conn} do
      %{view: setup_page(conn)}
    end

    test "desktop", %{view: view} do
      render_hook(view, "zoom-desktop", %{position: %{x: 0, y: 0}, delta: -1})
      assert %{x: 0.0, y: 0.0, height: 25, width: 25} == get_viewbox(view)
      render_hook(view, "zoom-desktop", %{position: %{x: 50, y: 50}, delta: 1})
      assert %{x: 2.5, y: 2.5, height: 20, width: 20} == get_viewbox(view)
      render_hook(view, "zoom-desktop", %{position: %{x: 0, y: 0}, delta: -100})

      assert %{x: 2.5, y: 2.5, height: @default_height, width: @default_width} ==
               get_viewbox(view)
    end

    test "mobile zoom-out", %{view: view} do
      original = %{position: %{x: 0, y: 0}, touches: [%{x: 0, y: 0}, %{x: 100, y: 100}]}

      zoom_mobile(view, original, [%{x: 40, y: 40}, %{x: 60, y: 60}])

      assert %{x: 0, y: 0, height: @default_height, width: @default_width} ==
               get_viewbox(view)
    end

    test "mobile zoom-out, same touches", %{view: view} do
      original = %{position: %{x: 0, y: 0}, touches: [%{x: 40, y: 40}, %{x: 60, y: 60}]}

      zoom_mobile(view, original, [%{x: 50, y: 50}, %{x: 50, y: 50}])
      assert %{x: 0, y: 0, height: @default_height, width: @default_width} == get_viewbox(view)
    end

    test "mobile move", %{view: view} do
      original = %{position: %{x: 10, y: 10}, touches: [%{x: 40, y: 40}, %{x: 60, y: 60}]}

      zoom_mobile(view, original, [%{x: 40, y: 40}, %{x: 60, y: 60}])

      assert %{x: 10, y: 10, height: 20, width: 20} == get_viewbox(view)

      zoom_mobile(view, original, [%{x: 50, y: 50}, %{x: 70, y: 70}])

      assert %{x: 8, y: 8, height: 20, width: 20} == get_viewbox(view)

      zoom_mobile(view, original, [%{x: 30, y: 30}, %{x: 50, y: 50}])

      assert %{x: 12, y: 12, height: 20, width: 20} == get_viewbox(view)
    end

    test "mobile zoom-in", %{view: view} do
      original = %{position: %{x: 0, y: 0}, touches: [%{x: 40, y: 40}, %{x: 60, y: 60}]}

      zoom_mobile(view, original, [%{x: 30, y: 30}, %{x: 70, y: 70}])

      assert %{x: 5, y: 5, height: 10, width: 10} == get_viewbox(view)
    end

    test "mobile zoom-in, same touches", %{view: view} do
      original = %{position: %{x: 0, y: 0}, touches: [%{x: 50, y: 50}, %{x: 50, y: 50}]}

      zoom_mobile(view, original, [%{x: 40, y: 40}, %{x: 60, y: 60}])

      assert %{x: 5, y: 5, height: 10, width: 10} == get_viewbox(view)
    end
  end

  defp get_viewbox(view) do
    [{x, ""}, {y, ""}, {width, ""}, {height, ""}] =
      view
      |> render()
      |> Floki.attribute("#default-body", "viewbox")
      |> List.first()
      |> String.split(~r/\s+/)
      |> Enum.map(&Float.parse/1)

    %{x: x, y: y, height: height, width: width}
  end

  defp render_automations(conn) do
    live_with_dependencies(conn, ExshomeAutomation, :automations)
  end

  defp render_dragend(view) do
    assert render_hook(view, "dragend", %{})
  end

  defp resize(view, %{height: height, width: width}) do
    assert render_hook(view, "resize", %{height: height, width: width})
  end

  defp select_background(view) do
    select_element(view, "default-canvas-background")
  end

  defp select_element(view, id) do
    assert selected =
             view
             |> render()
             |> Floki.find("##{id}")

    assert {x, ""} =
             selected
             |> Floki.attribute("x")
             |> List.first()
             |> Float.parse()

    assert {y, ""} =
             selected
             |> Floki.attribute("x")
             |> List.first()
             |> Float.parse()

    assert render_hook(view, "select", %{id: id, position: %{x: x, y: y}})
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
