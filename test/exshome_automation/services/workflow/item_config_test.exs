defmodule ExshomeAutomationTest.Services.Workflow.ItemConfigTest do
  use ExshomeTest.DataCase, async: true
  alias ExshomeAutomation.Services.Workflow.ItemConfig

  describe "compute svg path components" do
    @connector_width 4
    @connector_height 4
    @connector_offset 2
    @outline_width 1
    @min_width 25
    @min_height 10
    @action_width 6
    @action_offset 2
    @child_action_offset 5
    @child_action_separator_height 2
    @corner_height 1
    @offset_x @outline_width + @connector_width
    @offset_y @outline_width

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
               :child_action,
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
               {:vertical, -(@min_height - @connector_height - @connector_offset)},
               :parent_connector,
               {:vertical, -@connector_offset},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child connection, child height smaller than minimum" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [],
          child_connections: [%{height: @min_height - 1}],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               :child_connector,
               {:vertical, @min_height - @connector_offset - @connector_height},
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
          child_connections: [%{height: @min_height + 1}],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               :child_connector,
               {:vertical, @min_height + 1 - @connector_offset - @connector_height},
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
          child_actions: [%{height: @min_height - 1}],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      inner_action_width = @min_width - @child_action_offset

      left_height =
        @min_height + @min_height + @child_action_separator_height +
          @corner_height * 4

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               :child_action,
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
          child_actions: [%{height: @min_height + 1}],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      inner_action_width = @min_width - @child_action_offset

      left_height =
        @min_height + @min_height + 1 + @child_action_separator_height +
          @corner_height * 4

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @min_width},
               {:round_corner, :top_right},
               {:vertical, @min_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               :child_action,
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
        %{height: @min_height - 1},
        %{height: @min_height + 1}
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
      corners_height = length(child_components) * 4 * @corner_height

      left_height =
        child_connections_height + child_actions_height + separators_height + corners_height

      inner_action_width = @min_width - @child_action_offset

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @connector_offset},
               :parent_action,
               {:horizontal, @min_width - @action_offset - @action_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               :child_connector,
               {:vertical, @min_height - @connector_offset - @connector_height},
               {:vertical, @connector_offset},
               :child_connector,
               {:vertical, @min_height + 1 - @connector_offset - @connector_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               :child_action,
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               :child_action,
               {:horizontal, -@action_offset},
               {:round_corner, :inner_top_left},
               {:vertical, @min_height + 1},
               {:round_corner, :inner_bottom_left},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(@min_width - @action_width - @action_offset)},
               :child_action,
               {:horizontal, -@action_offset},
               {:round_corner, :bottom_left},
               {:vertical, -(left_height - @connector_height - @connector_offset)},
               :parent_connector,
               {:vertical, -@connector_offset},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end
  end
end
