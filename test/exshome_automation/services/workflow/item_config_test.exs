defmodule ExshomeAutomationTest.Services.Workflow.ItemConfigTest do
  use ExshomeTest.DataCase, async: true
  alias ExshomeAutomation.Services.Workflow.ItemConfig
  alias ExshomeAutomation.Services.Workflow.ItemProperties

  @connector_size 4
  @connector_offset 2
  @outline_size 1
  @corner_size 1
  @min_width 20
  @min_height 2 * @connector_offset + @connector_size + @outline_size
  @min_child_connection_height @min_height + 2 * @corner_size
  @action_width 6
  @action_height 2
  @action_offset 2
  @labels_gap_size 6
  @child_action_empty_height 2
  @min_child_action_offset 5
  @child_action_separator_height 1
  @letter_height 3
  @letter_width 1.85

  @offset_x @outline_size + @connector_size + @corner_size
  @offset_y @outline_size
  @item_label_x @outline_size * 2 + @connector_size
  @item_label_y @outline_size * 2 + @action_height + @letter_height

  describe "compute svg path components" do
    test "without connections" do
      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: "test",
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

    test "with large label" do
      label_letters = 32

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: String.duplicate("a", label_letters),
            child_actions: [],
            child_connections: [],
            parent: nil,
            has_next_action?: false
          },
          %{}
        )

      width = label_letters * @letter_width + @labels_gap_size

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -width},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with large child connection label" do
      label_letters = 32
      connection_letters = 30

      child_connector_label = String.duplicate("b", connection_letters)

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: String.duplicate("a", label_letters),
            child_actions: [],
            child_connections: [child_connector_label],
            parent: nil,
            has_next_action?: false
          },
          %{}
        )

      width =
        label_letters * @letter_width + @labels_gap_size + connection_letters * @letter_width +
          @outline_size

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               {:child_connector, child_connector_label},
               {:vertical,
                @min_child_connection_height - @connector_offset - @connector_size -
                  2 * @corner_size},
               {:round_corner, :bottom_right},
               {:horizontal, -width},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with large child action label" do
      action_letters = 32

      child_action_label = String.duplicate("a", action_letters)

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: "test",
            child_actions: [child_action_label],
            child_connections: [],
            parent: nil,
            has_next_action?: false
          },
          %{}
        )

      width = action_letters * @letter_width + @min_width + @outline_size

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(@min_width - @action_width - @action_offset - @corner_size)},
               {:child_action, child_action_label},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @child_action_empty_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, @min_width - @corner_size},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -width},
               {:round_corner, :bottom_left},
               {:vertical,
                -(@min_height + @child_action_empty_height + @corner_size * 2 +
                    @child_action_separator_height + @action_height)},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with previous action" do
      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: "test",
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
            label: "test",
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
            label: "test",
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
      item_label = "test"
      child_connection_label = "conn_1"

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: item_label,
            child_actions: [],
            child_connections: [child_connection_label],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      width =
        (String.length(item_label) + String.length(child_connection_label)) * @letter_width +
          @labels_gap_size + @corner_size

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               {:child_connector, "conn_1"},
               {:vertical, @min_height - @connector_offset - @connector_size},
               {:round_corner, :bottom_right},
               {:horizontal, -width},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child connection, child connected" do
      item_label = "test"
      child_connection_label = "conn_1"

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: item_label,
            child_actions: [],
            child_connections: [child_connection_label],
            has_next_action?: false,
            parent: nil
          },
          %{{:connection, child_connection_label} => %{height: @min_height, width: 0}}
        )

      width =
        (String.length(item_label) + String.length(child_connection_label)) * @letter_width +
          @labels_gap_size + @corner_size

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               {:child_connector, child_connection_label},
               {:vertical, @min_height - @connector_offset - @connector_size},
               {:round_corner, :bottom_right},
               {:horizontal, -width},
               {:round_corner, :bottom_left},
               {:vertical, -@min_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child action, child is not connected" do
      child_action_label = "action_1"

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: "test",
            child_actions: [child_action_label],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      child_label_width = String.length(child_action_label) * @letter_width
      width = child_label_width + @min_width + @outline_size

      inner_action_width = width - child_label_width - 2 * @corner_size

      left_height =
        @min_height + @child_action_empty_height + @child_action_separator_height +
          @corner_size * 4

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, child_action_label},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @child_action_empty_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -width},
               {:round_corner, :bottom_left},
               {:vertical, -left_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child action, child connected" do
      child_action_label = "action_1"

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: "test",
            child_actions: [child_action_label],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{{:action, child_action_label} => %{width: 0, height: @min_height}}
        )

      child_label_width = String.length(child_action_label) * @letter_width
      width = child_label_width + @min_width + @outline_size

      inner_action_width = width - child_label_width - 2 * @corner_size

      left_height =
        @min_height + @min_height + @child_action_empty_height + @child_action_separator_height +
          @corner_size * 4

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, child_action_label},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height + @child_action_empty_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -width},
               {:round_corner, :bottom_left},
               {:vertical, -left_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with multiple children" do
      item_label = "test"
      child_action_extra_height = 1
      child_action_label_1 = "action_1"
      child_action_label_2 = "action_2"
      child_connection_label_1 = "conn_1"
      child_connection_label_2 = "conn_2"

      child_actions = %{
        {:action, child_action_label_2} => %{height: @min_height, width: 0}
      }

      child_connections = %{
        {:connection, child_connection_label_2} => %{
          height: @min_height + child_action_extra_height,
          width: 0
        }
      }

      path_components =
        ItemConfig.compute_svg_components(
          %ItemConfig{
            label: item_label,
            child_actions: [child_action_label_1, child_action_label_2],
            child_connections: [child_connection_label_1, child_connection_label_2],
            has_next_action?: true,
            parent: :connection
          },
          Map.merge(child_actions, child_connections)
        )

      number_of_child_actions = 2

      max_child_action_label_size =
        Enum.max_by([child_action_label_1, child_action_label_2], &String.length/1)

      max_child_connection_label_size =
        Enum.max_by([child_connection_label_1, child_connection_label_2], &String.length/1)

      width =
        max(
          (String.length(item_label) + String.length(max_child_connection_label_size)) *
            @letter_width + @labels_gap_size,
          String.length(max_child_action_label_size) * @letter_width + @min_width + @corner_size
        )

      child_connections_height = @min_height + @min_height + child_action_extra_height
      child_actions_height = 2 * @child_action_empty_height + @min_height
      separators_height = number_of_child_actions * @child_action_separator_height
      corners_height = number_of_child_actions * 4 * @corner_size

      left_height =
        child_connections_height + child_actions_height + separators_height + corners_height +
          child_action_extra_height

      inner_action_width =
        width - String.length(max_child_action_label_size) * @letter_width - 2 * @corner_size

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               {:child_connector, child_connection_label_1},
               {:vertical, @min_child_connection_height - @connector_offset - @connector_size},
               {:vertical, @connector_offset},
               {:child_connector, child_connection_label_2},
               {:vertical, @min_height - @connector_offset - @connector_size},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, child_action_label_1},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @child_action_empty_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               {:child_action, child_action_label_2},
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height + @child_action_empty_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(width - @action_width - @action_offset)},
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
    @item_label "test"
    @empty_height @outline_size + @corner_size + @min_height + @corner_size + @outline_size
    @empty_width @outline_size * 2 + @corner_size * 2 + @connector_size + @min_width

    test "without connections" do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
            child_actions: [],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      assert %ItemProperties{
               height: @empty_height,
               width: @empty_width,
               labels: [
                 %{text: @item_label, y: @item_label_y, x: @item_label_x}
               ],
               raw_size: %{
                 height: @min_height + 2 * @corner_size,
                 width: @min_width + 2 * @corner_size
               },
               connectors: %{}
             } == item_properties
    end

    test "with previous action" do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
            child_actions: [],
            child_connections: [],
            has_next_action?: false,
            parent: :action
          },
          %{}
        )

      assert %ItemProperties{
               height: @empty_height,
               width: @empty_width,
               raw_size: %{
                 height: @min_height + 2 * @corner_size,
                 width: @min_width + 2 * @corner_size
               },
               labels: [
                 %{text: @item_label, y: @item_label_y, x: @item_label_x}
               ],
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

    test "with next action" do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
            child_actions: [],
            child_connections: [],
            has_next_action?: true,
            parent: nil
          },
          %{}
        )

      height = @empty_height + @action_height

      assert %ItemProperties{
               height: height,
               width: @empty_width,
               raw_size: %{
                 height: @min_height + 2 * @corner_size,
                 width: @min_width + 2 * @corner_size
               },
               labels: [
                 %{text: @item_label, y: @item_label_y, x: @item_label_x}
               ],
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

    test "with parent connection" do
      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
            child_actions: [],
            child_connections: [],
            has_next_action?: false,
            parent: :connection
          },
          %{}
        )

      assert %ItemProperties{
               height: @empty_height,
               width: @empty_width,
               raw_size: %{
                 height: @min_height + 2 * @corner_size,
                 width: @min_width + 2 * @corner_size
               },
               labels: [
                 %{text: @item_label, y: @item_label_y, x: @item_label_x}
               ],
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

    test "with child connection, child is not connected" do
      connector_label = "conn_1"

      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
            child_actions: [],
            child_connections: [connector_label],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      width =
        (String.length(@item_label) + String.length(connector_label)) * @letter_width +
          @labels_gap_size + @connector_size + 2 * @corner_size + 3 * @outline_size

      connector_label_x =
        width - 2 * @outline_size - @connector_size -
          String.length(connector_label) * @letter_width

      assert %ItemProperties{
               height: @empty_height,
               width: width,
               raw_size: %{
                 height: @min_height + 2 * @corner_size,
                 width: width - @connector_size - 2 * @corner_size
               },
               labels: [
                 %{text: @item_label, y: @item_label_y, x: @item_label_x},
                 %{text: connector_label, y: @item_label_y, x: connector_label_x}
               ],
               connectors: %{
                 {:connection, connector_label} => %{
                   x: width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    test "with child connection, child connected" do
      connector_label = "conn_1"

      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
            child_actions: [],
            child_connections: [connector_label],
            has_next_action?: false,
            parent: nil
          },
          %{
            {:connection, connector_label} => %{height: @min_height + 1, width: 0}
          }
        )

      width =
        (String.length(@item_label) + String.length(connector_label)) * @letter_width +
          @labels_gap_size + @connector_size + 2 * @corner_size + 3 * @outline_size

      connector_label_x =
        width - 2 * @outline_size - @connector_size -
          String.length(connector_label) * @letter_width

      assert %ItemProperties{
               height: @empty_height,
               width: width,
               raw_size: %{
                 height: @min_height + 2 * @corner_size,
                 width: width - 2 * @corner_size - @connector_size
               },
               labels: [
                 %{text: @item_label, y: @item_label_y, x: @item_label_x},
                 %{text: connector_label, y: @item_label_y, x: connector_label_x}
               ],
               connectors: %{
                 {:connection, connector_label} => %{
                   x: width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 }
               }
             } == item_properties
    end

    test "with child action, child is not connected" do
      action_label = "action_1"

      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
            child_actions: [action_label],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{}
        )

      height =
        @min_height + @child_action_empty_height + 3 * @corner_size +
          @child_action_separator_height + @min_child_action_offset

      raw_height =
        @min_height + @child_action_empty_height + 4 * @corner_size +
          @child_action_separator_height + 2 * @corner_size

      width =
        String.length(action_label) * @letter_width + @min_width + @connector_size * 2 +
          @outline_size

      action_y = @outline_size + 2 * @corner_size + @min_height

      action_x =
        2 * @outline_size + @connector_size + String.length(action_label) * @letter_width +
          @connector_offset + 2 * @corner_size

      assert %ItemProperties{
               height: height,
               width: width,
               raw_size: %{
                 height: raw_height,
                 width: width - 2 * @corner_size - @connector_size
               },
               labels: [
                 %{text: @item_label, x: @item_label_x, y: @item_label_y},
                 %{
                   text: action_label,
                   x: 2 * @outline_size + @connector_size,
                   y: action_y + @letter_height - @outline_size
                 }
               ],
               connectors: %{
                 {:action, action_label} => %{
                   x: action_x,
                   y: action_y,
                   width: @action_width,
                   height: @action_height
                 }
               }
             } == item_properties
    end

    test "with child action, child connected" do
      action_label = "action_1"

      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
            child_actions: [action_label],
            child_connections: [],
            has_next_action?: false,
            parent: nil
          },
          %{
            {:actton, action_label} => %{height: @min_height, width: 0}
          }
        )

      width =
        String.length(action_label) * @letter_width + @min_width + @connector_size * 2 +
          @outline_size

      action_y = @outline_size + 2 * @corner_size + @min_height

      action_x =
        2 * @outline_size + @connector_size + String.length(action_label) * @letter_width +
          @connector_offset + 2 * @corner_size

      assert %ItemProperties{
               height: @empty_height + @min_height - 2 * @corner_size,
               width: width,
               raw_size: %{
                 height: @empty_height + @min_height - 2 * @corner_size - 2 * @outline_size,
                 width: width - 2 * @corner_size - @connector_size
               },
               labels: [
                 %{text: @item_label, x: @item_label_x, y: @item_label_y},
                 %{
                   text: action_label,
                   x: 2 * @outline_size + @connector_size,
                   y: action_y + @letter_height - @outline_size
                 }
               ],
               connectors: %{
                 {:action, action_label} => %{
                   x: action_x,
                   y: action_y,
                   width: @action_width,
                   height: @action_height
                 }
               }
             } == item_properties
    end

    test "with multiple children" do
      child_actions = %{
        {:action, "action_2"} => %{height: @min_height, width: 0}
      }

      child_connections = %{
        {:connection, "conn_2"} => %{height: @min_height + 1, width: 0}
      }

      item_properties =
        compute_item_properties(
          %ItemConfig{
            label: @item_label,
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

      second_child_action_height =
        @min_height + @child_action_empty_height + 4 * @corner_size +
          @child_action_separator_height

      height =
        height_after_child_connectors + first_child_action_height + second_child_action_height +
          @corner_size + @outline_size + @action_height

      assert %ItemProperties{
               height: height,
               width: @min_width,
               raw_size: %{
                 height: height - 2 * @outline_size - @action_height,
                 width: @min_width + 2 * @corner_size
               },
               labels: [
                 %{text: @item_label, x: @item_label_x, y: @item_label_y}
               ],
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
                   x: @offset_x + @action_offset + @min_child_action_offset + @corner_size,
                   y: height_after_child_connectors + @corner_size,
                   width: @action_width,
                   height: @action_height
                 },
                 {:action, "action_2"} => %{
                   x: @offset_x + @action_offset + @min_child_action_offset + @corner_size,
                   y: height_after_child_connectors + first_child_action_height + @corner_size,
                   width: @action_width,
                   height: @action_height
                 },
                 {:connection, "conn_1"} => %{
                   x: @min_width - @outline_size - @connector_size,
                   y: @outline_size + @corner_size + @connector_offset,
                   width: @connector_size,
                   height: @connector_size
                 },
                 {:connection, "conn_2"} => %{
                   x: @min_width - @outline_size - @connector_size,
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
      |> ItemConfig.compute_item_properties(config)
    end
  end
end
