defmodule ExshomeAutomation.Services.Workflow.ItemConfig do
  @moduledoc """
  Editor item configuration.
  """
  defstruct [
    :has_previous_action?,
    :has_next_action?,
    :has_parent_connection?,
    child_connections: [],
    child_actions: []
  ]

  @type child_connection() :: %{
          height: number()
        }

  @type child_action() :: %{
          height: number()
        }

  @type t() :: %__MODULE__{
          has_previous_action?: boolean(),
          has_next_action?: boolean(),
          has_parent_connection?: boolean(),
          child_connections: [child_connection()],
          child_actions: [child_action()]
        }

  @offset_x 4
  @offset_y 2
  @component_width 25
  @component_height 10
  @action_offset 2
  @action_width 6
  @connector_height 2
  @connector_offset 2
  @child_action_offset 5
  @child_action_separator_height 2
  @corner_height 1

  @type svg_component() ::
          {:move, x :: number(), y :: number()}
          | {:horizontal, x :: number()}
          | {:vertical, y :: number()}
          | {:round_corner, :top_right | :bottom_right | :bottom_left | :top_left}
          | :close_path
          | :parent_action
          | :child_action
          | :parent_connector
          | :child_connector

  @spec compute_svg_components(t()) :: [svg_component()]
  def compute_svg_components(%__MODULE__{} = config) do
    []
    |> put_svg_component({:move, @offset_x, @offset_y})
    |> compute_component_top(config)
    |> put_svg_component({:round_corner, :top_right})
    |> compute_component_right(config)
    |> put_svg_component({:round_corner, :bottom_right})
    |> compute_component_bottom(config)
    |> put_svg_component({:round_corner, :bottom_left})
    |> compute_component_left(config)
    |> put_svg_component({:round_corner, :top_left})
    |> put_svg_component(:close_path)
    |> Enum.reverse()
  end

  @spec compute_component_top([svg_component()], t()) :: [svg_component()]
  defp compute_component_top(components, %__MODULE__{has_previous_action?: false}) do
    put_svg_component(components, {:horizontal, @component_width})
  end

  defp compute_component_top(components, %__MODULE__{}) do
    offset = @component_width - @action_offset - @action_width

    components
    |> put_svg_component({:horizontal, @action_offset})
    |> put_svg_component(:parent_action)
    |> put_svg_component({:horizontal, offset})
  end

  @spec compute_component_bottom([svg_component()], t()) :: [svg_component()]
  defp compute_component_bottom(components, %__MODULE__{has_next_action?: false}) do
    put_svg_component(components, {:horizontal, -@component_width})
  end

  defp compute_component_bottom(components, %__MODULE__{}) do
    offset = @component_width - @action_offset - @action_width

    components
    |> put_svg_component({:horizontal, -offset})
    |> put_svg_component(:child_action)
    |> put_svg_component({:horizontal, -@action_offset})
  end

  @spec compute_component_left([svg_component()], t()) :: [svg_component()]
  defp compute_component_left(
         components,
         %__MODULE__{has_parent_connection?: false} = config
       ) do
    height = compute_left_height(config)
    put_svg_component(components, {:vertical, -height})
  end

  defp compute_component_left(components, %__MODULE__{} = config) do
    height = compute_left_height(config)
    offset = height - @connector_height - @connector_offset

    components
    |> put_svg_component({:vertical, -offset})
    |> put_svg_component(:parent_connector)
    |> put_svg_component({:vertical, -@connector_offset})
  end

  defp compute_left_height(%__MODULE__{} = config) do
    connections_height =
      config.child_connections
      |> Enum.map(&max(&1.height, @component_height))
      |> Enum.sum()

    actions_height =
      config.child_actions
      |> Enum.map(&max(&1.height, @component_height))
      |> Enum.sum()

    actions_count = length(config.child_actions)
    action_separators_height = actions_count * @child_action_separator_height
    action_corners_height = actions_count * 2 * @corner_height
    total_actions_height = actions_height + action_separators_height + action_corners_height

    max(@component_height, connections_height) + total_actions_height
  end

  @spec compute_component_right([svg_component()], t()) :: [svg_component()]
  defp compute_component_right(components, %__MODULE__{child_actions: [], child_connections: []}) do
    put_svg_component(components, {:vertical, @component_height})
  end

  defp compute_component_right(components, %__MODULE__{} = config) do
    components
    |> compute_child_connections(config)
    |> compute_child_actions(config)
  end

  @spec compute_child_connections([svg_component()], t()) :: [svg_component()]
  defp compute_child_connections(components, %__MODULE__{child_connections: []}) do
    put_svg_component(components, {:vertical, @component_height})
  end

  defp compute_child_connections(components, %__MODULE__{} = config) do
    for %{height: height} <- config.child_connections, reduce: components do
      components ->
        component_height = max(height, @component_height)
        remaining_offset = component_height - @connector_offset - @connector_height

        components
        |> put_svg_component({:vertical, @connector_offset})
        |> put_svg_component(:child_connector)
        |> put_svg_component({:vertical, remaining_offset})
    end
  end

  @spec compute_child_actions([svg_component()], t()) :: [svg_component()]
  defp compute_child_actions(components, %__MODULE__{child_actions: []}) do
    components
  end

  defp compute_child_actions(components, %__MODULE__{} = config) do
    child_action_width = @component_width - @child_action_offset
    child_action_right_offset = child_action_width - @action_width - @action_offset

    for %{height: height} <- config.child_actions, reduce: components do
      components ->
        components
        |> put_svg_component({:round_corner, :bottom_right})
        |> put_svg_component({:horizontal, -child_action_right_offset})
        |> put_svg_component(:child_action)
        |> put_svg_component({:horizontal, -@action_offset})
        |> put_svg_component({:vertical, max(height, @component_height)})
        |> put_svg_component({:horizontal, child_action_width})
        |> put_svg_component({:round_corner, :top_right})
        |> put_svg_component({:vertical, @child_action_separator_height})
    end
  end

  @spec put_svg_component([svg_component()], svg_component()) :: [svg_component()]
  defp put_svg_component(components, component) do
    [component | components]
  end

  @spec svg_components_to_path([svg_component()]) :: String.t()
  def svg_components_to_path(components) do
    Enum.map_join(components, " ", &svg_to_string/1)
  end

  @spec svg_to_string(svg_component()) :: String.t()
  defp svg_to_string({:move, x, y}), do: "m #{x} #{y}"
  defp svg_to_string({:horizontal, x}), do: "h #{x}"
  defp svg_to_string({:vertical, y}), do: "v #{y}"
  defp svg_to_string({:round_corner, :top_right}), do: "q 1 0 1 1"
  defp svg_to_string({:round_corner, :bottom_right}), do: "q 0 1 -1 1"
  defp svg_to_string({:round_corner, :bottom_left}), do: "q -1 0 -1 -1"
  defp svg_to_string({:round_corner, :top_left}), do: "q 0 -1 1 -1"
  defp svg_to_string(:close_path), do: "z"

  defp svg_to_string(:parent_action),
    do: "l #{@action_width / 2} 2 l #{@action_width / 2} -2"

  defp svg_to_string(:child_action),
    do: "l -#{@action_width / 2} 2 l -#{@action_width / 2} -2"

  defp svg_to_string(:child_connector) do
    """
    v 0.2
    l -1 -0.2
    a 1 1 0 0 0 0 2
    l 1 -0.2
    v 0.2
    """
  end

  defp svg_to_string(:parent_connector) do
    """
    v -0.2
    l -1 0.2
    a 1 1 0 0 1 0 -2
    l 1 0.2
    v -0.2
    """
  end
end
