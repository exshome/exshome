defmodule ExshomeAutomationTest.Services.Workflow.ItemConfigTest do
  use ExshomeTest.DataCase, async: true
  alias ExshomeAutomation.Services.Workflow.ItemConfig
  alias ExshomeAutomation.Services.Workflow.ItemConfig.Properties

  @connector_size 4
  @connector_offset 2
  @outline_size 1
  @min_width 25
  @min_height 10
  @action_height 2
  @action_width 6
  @action_offset 2
  @child_action_offset 5
  @child_action_separator_height 2
  @corner_size 1
  @offset_x @outline_size + @connector_size + @corner_size
  @offset_y @outline_size

  describe "compute svg path components" do
    test "without connections" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@min_width},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with previous action" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: true
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @action_offset},
               {:parent_action, "parent"},
               {:horizontal, @min_width - @action_offset - @action_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@min_width},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with next action" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [],
          child_connections: [],
          has_next_action?: true,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(@min_width - @action_width - @action_offset)},
               {:child_action, "next_action"},
               {:horizontal, -@action_offset},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with parent connection" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: true,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@min_width},
               {:round_corner, :bottom_left},
               {:vertical, -(@min_height - @connector_size - @connector_offset)},
               {:parent_connector, "parent"},
               {:vertical, -@connector_offset},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child connection, child height smaller than minimum" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [],
          child_connections: [%{height: @min_height - 1, id: "conn_1"}],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               {:child_connector, "conn_1"},
               {:vertical, @min_height - @connector_offset - @connector_size},
               {:round_corner, :bottom_right},
               {:horizontal, -@min_width},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child connection, child height larger than minimum" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [],
          child_connections: [%{height: @min_height + 1, id: "conn_1"}],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               {:child_connector, "conn_1"},
               {:vertical, @min_height + 1 - @connector_offset - @connector_size},
               {:round_corner, :bottom_right},
               {:horizontal, -@min_width},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height - 1},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child action, child height smaller than minimum" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [%{height: @min_height - 1, id: "action_1"}],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      inner_action_width = @min_width - @child_action_offset - @corner_size

      left_height =
        @min_height + @min_height + @child_action_separator_height +
          @corner_size * 4

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, "action_1"},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@min_width},
               {:round_corner, :bottom_left},
               {:vertical, -left_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child action, child height larger than minimum" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [%{height: @min_height + 1, id: "action_1"}],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      inner_action_width = @min_width - @child_action_offset - @corner_size

      left_height =
        @min_height + @min_height + 1 + @child_action_separator_height +
          @corner_size * 4

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, "action_1"},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height + 1},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@min_width},
               {:round_corner, :bottom_left},
               {:vertical, -left_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with all possible connections" do
      child_components = [
        %{height: @min_height - 1, id: "1"},
        %{height: @min_height + 1, id: "2"}
      ]

      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: child_components,
          child_connections: child_components,
          has_next_action?: true,
          has_parent_connection?: true,
          has_previous_action?: true
        })

      child_connections_height = @min_height + @min_height + 1
      child_actions_height = @min_height + @min_height + 1
      separators_height = length(child_components) * @child_action_separator_height
      corners_height = length(child_components) * 4 * @corner_size

      left_height =
        child_connections_height + child_actions_height + separators_height + corners_height

      inner_action_width = @min_width - @child_action_offset - @corner_size

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @connector_offset},
               {:parent_action, "parent"},
               {:horizontal, @min_width - @action_offset - @action_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               {:child_connector, "1"},
               {:vertical, @min_height - @connector_offset - @connector_size},
               {:vertical, @connector_offset},
               {:child_connector, "2"},
               {:vertical, @min_height + 1 - @connector_offset - @connector_size},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, "1"},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, "2"},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height + 1},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(@min_width - @action_width - @action_offset)},
               {:child_action, "next_action"},
               {:horizontal, -@action_offset},
               {:round_corner, :bottom_left},
               {:vertical, -(left_height - @connector_size - @connector_offset)},
               {:parent_connector, "parent"},
               {:vertical, -@connector_offset},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end
  end

  describe "compute item properties" do
    setup do
      empty_height = @outline_size + @corner_size + @min_height + @corner_size + @outline_size

      empty_width =
        @outline_size + @connector_size + @corner_size + @min_width + @corner_size +
          @outline_size

      %{empty_height: empty_height, empty_width: empty_width}
    end

    test "without connections", %{empty_height: height, empty_width: width} do
      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: [],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert %Properties{
               height: height,
               width: width,
               connectors: %{}
             } == item_properties
    end

    test "with previous action", %{empty_height: empty_height, empty_width: empty_width} do
      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: [],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: true
        })

      assert %Properties{
               height: empty_height,
               width: empty_width,
               connectors: %{
                 {:action_in, "parent"} => %{
                   x: @offset_x + @action_offset,
                   y: @outline_size,
                   width: @action_width,
                   height: @action_height
                 }
               }
             } == item_properties
    end

    test "with next action", %{empty_height: empty_height, empty_width: empty_width} do
      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: [],
          child_connections: [],
          has_next_action?: true,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      height = empty_height + @action_height

      assert %Properties{
               height: height,
               width: empty_width,
               connectors: %{
                 {:action_out, "next_action"} => %{
                   x: @offset_x + @action_offset,
                   y: height - @action_height - @outline_size,
                   width: @action_width,
                   height: @action_height
                 }
               }
             } == item_properties
    end

    test "with parent connection", %{empty_height: empty_height, empty_width: empty_width} do
      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: [],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: true,
          has_previous_action?: false
        })

      assert %Properties{
               height: empty_height,
               width: empty_width,
               connectors: %{
                 {:connector_out, "parent"} => %{
                   x: @outline_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    test "with child connection, child height smaller than minimum", %{
      empty_height: empty_height,
      empty_width: empty_width
    } do
      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: [],
          child_connections: [%{height: @min_height - 1, id: "conn_1"}],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert %Properties{
               height: empty_height,
               width: empty_width,
               connectors: %{
                 {:connector_in, "conn_1"} => %{
                   x: empty_width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    test "with child connection, child height larger than minimum", %{
      empty_height: empty_height,
      empty_width: empty_width
    } do
      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: [],
          child_connections: [%{height: @min_height + 1, id: "conn_1"}],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert %Properties{
               height: empty_height + 1,
               width: empty_width,
               connectors: %{
                 {:connector_in, "conn_1"} => %{
                   x: empty_width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    test "with child action, child height smaller than minimum", %{
      empty_height: empty_height,
      empty_width: empty_width
    } do
      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: [%{height: @min_height - 1, id: "action_1"}],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      height = empty_height + @min_height + 4 * @corner_size + @child_action_separator_height

      assert %Properties{
               height: height,
               width: empty_width,
               connectors: %{
                 {:action_out, "action_1"} => %{
                   x: @offset_x + @child_action_offset + @corner_size + @action_offset,
                   y: @offset_y + @corner_size + @min_height + @corner_size,
                   width: @action_width,
                   height: @action_height
                 }
               }
             } == item_properties
    end

    test "with child action, child height larger than minimum", %{
      empty_height: empty_height,
      empty_width: empty_width
    } do
      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: [%{height: @min_height + 1, id: "action_1"}],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      height = empty_height + @min_height + 4 * @corner_size + @child_action_separator_height + 1

      assert %Properties{
               height: height,
               width: empty_width,
               connectors: %{
                 {:action_out, "action_1"} => %{
                   x: @offset_x + @child_action_offset + @corner_size + @action_offset,
                   y: @offset_y + @corner_size + @min_height + @corner_size,
                   width: @action_width,
                   height: @action_height
                 }
               }
             } == item_properties
    end

    test "with all possible connections", %{empty_width: empty_width} do
      child_components = [
        %{height: @min_height - 1, id: "1"},
        %{height: @min_height + 1, id: "2"}
      ]

      item_properties =
        compute_item_properties(%ItemConfig{
          child_actions: child_components,
          child_connections: child_components,
          has_next_action?: true,
          has_parent_connection?: true,
          has_previous_action?: true
        })

      first_connector_block_height = @min_height
      second_connector_block_height = @min_height + 1

      height_after_child_connectors =
        @outline_size + @corner_size + first_connector_block_height +
          second_connector_block_height

      first_child_action_height = @min_height + 4 * @corner_size + @child_action_separator_height

      second_child_action_height =
        @min_height + 1 + 4 * @corner_size + @child_action_separator_height

      height =
        height_after_child_connectors + first_child_action_height + second_child_action_height +
          @corner_size + @outline_size + @action_height

      assert %Properties{
               height: height,
               width: empty_width,
               connectors: %{
                 {:action_in, "parent"} => %{
                   x: @offset_x + @action_offset,
                   y: @offset_y,
                   width: @action_width,
                   height: @action_height
                 },
                 {:action_out, "next_action"} => %{
                   x: @offset_x + @action_offset,
                   y: height - @outline_size - @action_height,
                   width: @action_width,
                   height: @action_height
                 },
                 {:action_out, "1"} => %{
                   x: @offset_x + @action_offset + @child_action_offset + @corner_size,
                   y: height_after_child_connectors + @corner_size,
                   width: @action_width,
                   height: @action_height
                 },
                 {:action_out, "2"} => %{
                   x: @offset_x + @action_offset + @child_action_offset + @corner_size,
                   y: height_after_child_connectors + first_child_action_height + @corner_size,
                   width: @action_width,
                   height: @action_height
                 },
                 {:connector_in, "1"} => %{
                   x: empty_width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 },
                 {:connector_in, "2"} => %{
                   x: empty_width - @outline_size - @connector_size,
                   y:
                     @outline_size + @corner_size + @connector_offset +
                       first_connector_block_height,
                   width: @connector_size,
                   height: @connector_size
                 },
                 {:connector_out, "parent"} => %{
                   x: @outline_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    @spec compute_item_properties(ItemConfig.t()) :: Properties.t()
    defp compute_item_properties(%ItemConfig{} = config) do
      config
      |> ItemConfig.compute_svg_components()
      |> ItemConfig.compute_item_properties()
    end
  end
end
