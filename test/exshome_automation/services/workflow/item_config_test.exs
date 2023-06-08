defmodule ExshomeAutomationTest.Services.Workflow.ItemConfigTest do
  use ExshomeTest.DataCase, async: true
  alias ExshomeAutomation.Services.Workflow.ItemConfig

  describe "compute svg path components" do
    @offset_x 4
    @offset_y 2
    @component_width 25
    @component_height 10
    @action_width 6
    @action_offset 2
    @connector_height 2
    @connector_offset 2
    @child_action_offset 5
    @child_action_separator_height 2
    @corner_height 1

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
               {:horizontal, @component_width},
               {:round_corner, :top_right},
               {:vertical, @component_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@component_width},
               {:round_corner, :bottom_left},
               {:vertical, -@component_height},
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
               {:horizontal, @component_width},
               {:round_corner, :top_right},
               {:vertical, @component_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(@component_width - @action_width - @action_offset)},
               :child_action,
               {:horizontal, -@action_offset},
               {:round_corner, :bottom_left},
               {:vertical, -@component_height},
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
               {:horizontal, @component_width},
               {:round_corner, :top_right},
               {:vertical, @component_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@component_width},
               {:round_corner, :bottom_left},
               {:vertical, -(@component_height - @connector_height - @connector_offset)},
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
          child_connections: [%{height: @component_height - 1}],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @component_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               :child_connector,
               {:vertical, @component_height - @connector_offset - @connector_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@component_width},
               {:round_corner, :bottom_left},
               {:vertical, -@component_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child connection, child height larger than minimum" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [],
          child_connections: [%{height: @component_height + 1}],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @component_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               :child_connector,
               {:vertical, @component_height + 1 - @connector_offset - @connector_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@component_width},
               {:round_corner, :bottom_left},
               {:vertical, -@component_height - 1},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child action, child height smaller than minimum" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [%{height: @component_height - 1}],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      inner_action_width = @component_width - @child_action_offset

      left_height =
        @component_height + @component_height + @child_action_separator_height +
          @corner_height * 2

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @component_width},
               {:round_corner, :top_right},
               {:vertical, @component_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               :child_action,
               {:horizontal, -@action_offset},
               {:vertical, @component_height},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@component_width},
               {:round_corner, :bottom_left},
               {:vertical, -left_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with child action, child height larger than minimum" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [%{height: @component_height + 1}],
          child_connections: [],
          has_next_action?: false,
          has_parent_connection?: false,
          has_previous_action?: false
        })

      inner_action_width = @component_width - @child_action_offset

      left_height =
        @component_height + @component_height + 1 + @child_action_separator_height +
          @corner_height * 2

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @component_width},
               {:round_corner, :top_right},
               {:vertical, @component_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               :child_action,
               {:horizontal, -@action_offset},
               {:vertical, @component_height + 1},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -@component_width},
               {:round_corner, :bottom_left},
               {:vertical, -left_height},
               {:round_corner, :top_left},
               :close_path
             ] == path_components
    end

    test "with all possible connections" do
      path_components =
        ItemConfig.compute_svg_components(%ItemConfig{
          child_actions: [%{height: @component_height - 1}, %{height: @component_height + 1}],
          child_connections: [%{height: @component_height - 1}, %{height: @component_height + 1}],
          has_next_action?: true,
          has_parent_connection?: true,
          has_previous_action?: true
        })

      child_connections_height = @component_height + @component_height + 1
      child_actions_height = @component_height + @component_height + 1
      separators_height = 2 * @child_action_separator_height
      corners_height = 2 * 2 * @corner_height

      left_height =
        child_connections_height + child_actions_height + separators_height + corners_height

      inner_action_width = @component_width - @child_action_offset

      assert [
               {:move, @offset_x, @offset_y},
               {:horizontal, @connector_offset},
               :parent_action,
               {:horizontal, @component_width - @action_offset - @action_width},
               {:round_corner, :top_right},
               {:vertical, @connector_offset},
               :child_connector,
               {:vertical, @component_height - @connector_offset - @connector_height},
               {:vertical, @connector_offset},
               :child_connector,
               {:vertical, @component_height + 1 - @connector_offset - @connector_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               :child_action,
               {:horizontal, -@action_offset},
               {:vertical, @component_height},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(inner_action_width - @action_offset - @action_width)},
               :child_action,
               {:horizontal, -@action_offset},
               {:vertical, @component_height + 1},
               {:horizontal, inner_action_width},
               {:round_corner, :top_right},
               {:vertical, @child_action_separator_height},
               {:round_corner, :bottom_right},
               {:horizontal, -(@component_width - @action_width - @action_offset)},
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
