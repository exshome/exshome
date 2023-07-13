defmodule ExshomeAutomationTest.Services.Workflow.ItemConfigTest do
  use ExshomeTest.DataCase, async: true
  alias ExshomeAutomation.Services.Workflow.ItemConfig
  alias ExshomeAutomation.Services.Workflow.ItemProperties

  @connector_size 4
  @connector_offset 2
  @outline_size 1
  @min_width 25
  @min_height 10
  @action_height 2
  @action_width 6
  @action_offset 2
  @child_action_empty_height 3
  @child_action_offset 5
  @child_action_separator_height 2
  @corner_size 1
  @offset_x @outline_size + @connector_size + @corner_size
  @offset_y @outline_size

  describe "compute svg path components" do
    test "without connections" do
      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: [],
            child_connections: [],
            parent: nil,
            has_next_action?: false
          },
          %{}
        )

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
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: [],
            child_connections: [],
            has_next_action?: false,
            parent: :action
          },
          %{}
        )

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @action_offset},
               :parent_action,
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
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: [],
            child_connections: [],
            has_next_action?: true,
            parent: nil
          },
          %{}
        )

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(@min_width - @action_width - @action_offset)},
               {:child_action, :next_action},
               {:horizontal, -@action_offset},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with parent connection" do
      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: [],
            child_connections: [],
            has_next_action?: false,
            parent: :connection
          },
          %{}
        )

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@min_width},
               {:round_corner, :bottom_left},
               {:vertical, -(@min_height - @connector_size - @connector_offset)},
               :parent_connector,
               {:vertical, -@connector_offset},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child connection, child is not connected" do
      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: [],
            child_connections: ["conn_1"],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

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

    test "with child connection, child connected" do
      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: [],
            child_connections: ["conn_1"],
            has_next_action?: false,
            parent: nil
          },
          %{{:connection, "conn_1"} => %{height: @min_height, width: 0}}
        )

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

    test "with child action, child is not connected" do
      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: ["action_1"],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      inner_action_width = @min_width - @child_action_offset - @corner_size

      left_height =
        @min_height + @child_action_empty_height + @child_action_separator_height +
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
               {:vertical, @child_action_empty_height},
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

    test "with child action, child connected" do
      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: ["action_1"],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{{:action, "action_1"} => %{width: 0, height: @min_height}}
        )

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

    test "with multiple children" do
      child_actions = %{
        {:action, "action_2"} => %{height: @min_height, width: 0}
      }

      child_connections = %{
        {:connection, "conn_2"} => %{height: @min_height, width: 0}
      }

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            child_actions: ["action_1", "action_2"],
            child_connections: ["conn_1", "conn_2"],
            has_next_action?: true,
            parent: :connection
          },
          Map.merge(child_actions, child_connections)
        )

      number_of_child_actions = 2

      child_connections_height = @min_height + @min_height
      child_actions_height = @child_action_empty_height + @min_height
      separators_height = number_of_child_actions * @child_action_separator_height
      corners_height = number_of_child_actions * 4 * @corner_size

      left_height =
        child_connections_height + child_actions_height + separators_height + corners_height

      inner_action_width = @min_width - @child_action_offset - @corner_size

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               {:child_connector, "conn_1"},
               {:vertical, @min_height - @connector_offset - @connector_size},
               {:vertical, @connector_offset},
               {:child_connector, "conn_2"},
               {:vertical, @min_height - @connector_offset - @connector_size},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, "action_1"},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @child_action_empty_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, "action_2"},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(@min_width - @action_width - @action_offset)},
               {:child_action, :next_action},
               {:horizontal, -@action_offset},
               {:round_corner, :bottom_left},
               {:vertical, -(left_height - @connector_size - @connector_offset)},
               :parent_connector,
               {:vertical, -@connector_offset},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end
  end

  describe "compute item properties" do
    setup do
      empty_height =
        @outline_size + @corner_size + @min_height + @corner_size + @outline_size

      empty_width =
        @outline_size + @connector_size + @corner_size + @min_width + @corner_size +
          @outline_size

      %{empty_height: empty_height, empty_width: empty_width}
    end

    test "without connections", %{empty_height: height, empty_width: width} do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            child_actions: [],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      assert %ItemProperties{
               height: height,
               width: width,
               connectors: %{}
             } == item_properties
    end

    test "with previous action", %{empty_height: empty_height, empty_width: empty_width} do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            child_actions: [],
            child_connections: [],
            has_next_action?: false,
            parent: :action
          },
          %{}
        )

      assert %ItemProperties{
               height: empty_height,
               width: empty_width,
               connectors: %{
                 parent_action: %{
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
        compute_item_properties(
          %ItemConfig{
            child_actions: [],
            child_connections: [],
            has_next_action?: true,
            parent: nil
          },
          %{}
        )

      height = empty_height + @action_height

      assert %ItemProperties{
               height: height,
               width: empty_width,
               connectors: %{
                 {:action, :next_action} => %{
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
        compute_item_properties(
          %ItemConfig{
            child_actions: [],
            child_connections: [],
            has_next_action?: false,
            parent: :connection
          },
          %{}
        )

      assert %ItemProperties{
               height: empty_height,
               width: empty_width,
               connectors: %{
                 parent_connector: %{
                   x: @outline_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    test "with child connection, child is not connected", %{
      empty_height: empty_height,
      empty_width: empty_width
    } do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            child_actions: [],
            child_connections: ["conn_1"],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      assert %ItemProperties{
               height: empty_height,
               width: empty_width,
               connectors: %{
                 {:connector, "conn_1"} => %{
                   x: empty_width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    test "with child connection, child connected", %{
      empty_height: empty_height,
      empty_width: empty_width
    } do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            child_actions: [],
            child_connections: ["conn_1"],
            has_next_action?: false,
            parent: nil
          },
          %{
            {:connection, "conn_1"} => %{height: @min_height + 1, width: 0}
          }
        )

      assert %ItemProperties{
               height: empty_height + 1,
               width: empty_width,
               connectors: %{
                 {:connector, "conn_1"} => %{
                   x: empty_width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    test "with child action, child is not connected", %{
      empty_height: empty_height,
      empty_width: empty_width
    } do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            child_actions: ["action_1"],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      height =
        empty_height + @child_action_empty_height + 4 * @corner_size +
          @child_action_separator_height

      assert %ItemProperties{
               height: height,
               width: empty_width,
               connectors: %{
                 {:action, "action_1"} => %{
                   x: @offset_x + @child_action_offset + @corner_size + @action_offset,
                   y: @offset_y + @corner_size + @min_height + @corner_size,
                   width: @action_width,
                   height: @action_height
                 }
               }
             } == item_properties
    end

    test "with child action, child connected", %{
      empty_height: empty_height,
      empty_width: empty_width
    } do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            child_actions: ["action_1"],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{
            {:actton, "action_1"} => %{height: @min_height, width: 0}
          }
        )

      assert %ItemProperties{
               height: empty_height + @min_height - 1,
               width: empty_width,
               connectors: %{
                 {:action, "action_1"} => %{
                   x: @offset_x + @child_action_offset + @corner_size + @action_offset,
                   y: @offset_y + @corner_size + @min_height + @corner_size,
                   width: @action_width,
                   height: @action_height
                 }
               }
             } == item_properties
    end

    test "with multiple children", %{empty_width: empty_width} do
      child_actions = %{
        {:action, "action_2"} => %{height: @min_height, width: 0}
      }

      child_connections = %{
        {:connection, "conn_2"} => %{height: @min_height + 1, width: 0}
      }

      item_properties =
        compute_item_properties(
          %ItemConfig{
            child_actions: ["action_1", "action_2"],
            child_connections: ["conn_1", "conn_2"],
            has_next_action?: true,
            parent: :action
          },
          Map.merge(child_actions, child_connections)
        )

      first_connector_block_height = @min_height
      second_connector_block_height = @min_height + 1

      height_after_child_connectors =
        @outline_size + @corner_size + first_connector_block_height +
          second_connector_block_height

      first_child_action_height =
        @child_action_empty_height + 4 * @corner_size + @child_action_separator_height

      second_child_action_height = @min_height + 4 * @corner_size + @child_action_separator_height

      height =
        height_after_child_connectors + first_child_action_height + second_child_action_height +
          @corner_size + @outline_size + @action_height

      assert %ItemProperties{
               height: height,
               width: empty_width,
               connectors: %{
                 :parent_action => %{
                   x: @offset_x + @action_offset,
                   y: @offset_y,
                   width: @action_width,
                   height: @action_height
                 },
                 {:action, :next_action} => %{
                   x: @offset_x + @action_offset,
                   y: height - @outline_size - @action_height,
                   width: @action_width,
                   height: @action_height
                 },
                 {:action, "action_1"} => %{
                   x: @offset_x + @action_offset + @child_action_offset + @corner_size,
                   y: height_after_child_connectors + @corner_size,
                   width: @action_width,
                   height: @action_height
                 },
                 {:action, "action_2"} => %{
                   x: @offset_x + @action_offset + @child_action_offset + @corner_size,
                   y: height_after_child_connectors + first_child_action_height + @corner_size,
                   width: @action_width,
                   height: @action_height
                 },
                 {:connector, "conn_1"} => %{
                   x: empty_width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 },
                 {:connector, "conn_2"} => %{
                   x: empty_width - @outline_size - @connector_size,
                   y:
                     @outline_size + @corner_size + @connector_offset +
                       first_connector_block_height,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    @spec compute_item_properties(ItemConfig.t(), map()) :: ItemProperties.t()
    defp compute_item_properties(%ItemConfig{} = config, connections) do
      config
      |> ItemConfig.compute_svg_components(connections)
      |> ItemConfig.compute_item_properties()
    end
  end
end
