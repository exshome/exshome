defmodule ExshomeAutomation.Services.Workflow.ItemConfig do
  @moduledoc """
  Editor item configuration.
  """
  defmodule Properties do
    @moduledoc """
    Struct for storing item property settings
    """

    defstruct [
      :height,
      :width,
      connectors: %{}
    ]

    @type connector_key() ::
            {:action_in | :action_out | :connector_in | :connector_out, id :: String.t()}
    @type connector_position() :: %{
            x: number(),
            y: number(),
            height: number(),
            width: number()
          }
    @type connector_mapping() :: %{connector_key() => connector_position()}

    @type t() :: %__MODULE__{
            height: number(),
            width: number(),
            connectors: connector_mapping()
          }
  end

  defstruct [
    :has_previous_action?,
    :has_next_action?,
    :has_parent_connection?,
    child_connections: [],
    child_actions: []
  ]

  @type child_connection() :: %{
          id: String.t(),
          height: number()
        }

  @type child_action() :: %{
          id: String.t(),
          height: number()
        }

  @type t() :: %__MODULE__{
          has_previous_action?: boolean(),
          has_next_action?: boolean(),
          has_parent_connection?: boolean(),
          child_connections: [child_connection()],
          child_actions: [child_action()]
        }

  @connector_size 4
  @connector_offset 2
  @outline_size 1
  @min_width 25
  @min_height 10
  @action_width 6
  @action_height 2
  @action_offset 2
  @child_action_offset 5
  @child_action_separator_height 2
  @corner_size 1

  @type svg_component() ::
          {:move, x :: number(), y :: number()}
          | {:horizontal, x :: number()}
          | {:vertical, y :: number()}
          | {:round_corner,
             :top_right
             | :bottom_right
             | :bottom_left
             | :top_left
             | :inner_top_left
             | :inner_bottom_left}
          | :close_path
          | {:parent_action, String.t()}
          | {:child_action, String.t()}
          | {:parent_connector, String.t()}
          | {:child_connector, String.t()}

  @spec compute_svg_components(t()) :: [svg_component()]
  def compute_svg_components(%__MODULE__{} = config) do
    []
    |> put_svg_component({:move, @connector_size + @outline_size + @corner_size, @outline_size})
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
    put_svg_component(components, {:horizontal, @min_width})
  end

  defp compute_component_top(components, %__MODULE__{}) do
    offset = @min_width - @action_offset - @action_width

    components
    |> put_svg_component({:horizontal, @action_offset})
    |> put_svg_component({:parent_action, "parent"})
    |> put_svg_component({:horizontal, offset})
  end

  @spec compute_component_bottom([svg_component()], t()) :: [svg_component()]
  defp compute_component_bottom(components, %__MODULE__{has_next_action?: false}) do
    put_svg_component(components, {:horizontal, -@min_width})
  end

  defp compute_component_bottom(components, %__MODULE__{}) do
    offset = @min_width - @action_offset - @action_width

    components
    |> put_svg_component({:horizontal, -offset})
    |> put_svg_component({:child_action, "next_action"})
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
    offset = height - @connector_size - @connector_offset

    components
    |> put_svg_component({:vertical, -offset})
    |> put_svg_component({:parent_connector, "parent"})
    |> put_svg_component({:vertical, -@connector_offset})
  end

  defp compute_left_height(%__MODULE__{} = config) do
    connections_height =
      config.child_connections
      |> Enum.map(&max(&1.height, @min_height))
      |> Enum.sum()

    actions_height =
      config.child_actions
      |> Enum.map(&max(&1.height, @min_height))
      |> Enum.sum()

    actions_count = length(config.child_actions)
    action_separators_height = actions_count * @child_action_separator_height
    action_corners_height = actions_count * 4 * @corner_size
    total_actions_height = actions_height + action_separators_height + action_corners_height

    max(@min_height, connections_height) + total_actions_height
  end

  @spec compute_component_right([svg_component()], t()) :: [svg_component()]
  defp compute_component_right(components, %__MODULE__{child_actions: [], child_connections: []}) do
    put_svg_component(components, {:vertical, @min_height})
  end

  defp compute_component_right(components, %__MODULE__{} = config) do
    components
    |> compute_child_connections(config)
    |> compute_child_actions(config)
  end

  @spec compute_child_connections([svg_component()], t()) :: [svg_component()]
  defp compute_child_connections(components, %__MODULE__{child_connections: []}) do
    put_svg_component(components, {:vertical, @min_height})
  end

  defp compute_child_connections(components, %__MODULE__{} = config) do
    for %{height: height, id: id} <- config.child_connections, reduce: components do
      components ->
        component_height = max(height, @min_height)
        remaining_offset = component_height - @connector_offset - @connector_size

        components
        |> put_svg_component({:vertical, @connector_offset})
        |> put_svg_component({:child_connector, id})
        |> put_svg_component({:vertical, remaining_offset})
    end
  end

  @spec compute_child_actions([svg_component()], t()) :: [svg_component()]
  defp compute_child_actions(components, %__MODULE__{child_actions: []}) do
    components
  end

  defp compute_child_actions(components, %__MODULE__{} = config) do
    child_action_width = @min_width - @child_action_offset - @corner_size
    child_action_right_offset = child_action_width - @action_width - @action_offset

    for %{height: height, id: id} <- config.child_actions, reduce: components do
      components ->
        components
        |> put_svg_component({:round_corner, :bottom_right})
        |> put_svg_component({:horizontal, -child_action_right_offset})
        |> put_svg_component({:child_action, id})
        |> put_svg_component({:horizontal, -@action_offset})
        |> put_svg_component({:round_corner, :inner_top_left})
        |> put_svg_component({:vertical, max(height, @min_height)})
        |> put_svg_component({:round_corner, :inner_bottom_left})
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
  defp svg_to_string(:close_path), do: "z"

  defp svg_to_string({:round_corner, :top_right}),
    do: "q #{@corner_size} 0 #{@corner_size} #{@corner_size}"

  defp svg_to_string({:round_corner, :bottom_right}),
    do: "q 0 #{@corner_size} -#{@corner_size} #{@corner_size}"

  defp svg_to_string({:round_corner, :bottom_left}),
    do: "q -#{@corner_size} 0 -#{@corner_size} -#{@corner_size}"

  defp svg_to_string({:round_corner, :top_left}),
    do: "q 0 -#{@corner_size} #{@corner_size} -#{@corner_size}"

  defp svg_to_string({:round_corner, :inner_top_left}),
    do: "q -#{@corner_size} 0 -#{@corner_size} #{@corner_size}"

  defp svg_to_string({:round_corner, :inner_bottom_left}),
    do: "q 0 #{@corner_size} #{@corner_size} #{@corner_size}"

  defp svg_to_string({:parent_action, _}),
    do: "l #{@action_width / 2} 2 l #{@action_width / 2} -2"

  defp svg_to_string({:child_action, _}),
    do: "l -#{@action_width / 2} 2 l -#{@action_width / 2} -2"

  defp svg_to_string({:child_connector, _}) do
    """
    v #{@connector_size / 8}
    l -#{@connector_size / 2} -#{@connector_size / 8}
    a #{@connector_size / 2} #{@connector_size / 2} 0 0 0 0 #{@connector_size}
    l #{@connector_size / 2} -#{@connector_size / 8}
    v #{@connector_size / 8}
    """
  end

  defp svg_to_string({:parent_connector, _}) do
    """
    v -#{@connector_size / 8}
    l -#{@connector_size / 2} #{@connector_size / 8}
    a #{@connector_size / 2} #{@connector_size / 2} 0 0 1 0 -#{@connector_size}
    l #{@connector_size / 2} #{@connector_size / 8}
    v -#{@connector_size / 8}
    """
  end

  @type property_data() :: %{
          x: number(),
          y: number(),
          width: number(),
          height: number(),
          connectors: Properties.connector_mapping()
        }

  @spec compute_item_properties([svg_component()]) :: Properties.t()
  def compute_item_properties(svg_components) do
    initial_data = %{x: 0, y: 0, width: 0, height: 0, connectors: %{}}

    item_data =
      for component <- svg_components, reduce: initial_data do
        intermediate_data -> collect_item_data(component, intermediate_data)
      end

    %Properties{
      height: item_data.height + @outline_size,
      width: item_data.width + @outline_size,
      connectors: item_data.connectors
    }
  end

  @spec collect_item_data(svg_component(), property_data()) :: property_data()
  defp collect_item_data({:move, x, y}, data), do: update_position(data, %{x: x, y: y})
  defp collect_item_data({:horizontal, x}, data), do: update_position(data, %{x: x, y: 0})
  defp collect_item_data({:vertical, y}, data), do: update_position(data, %{x: 0, y: y})
  defp collect_item_data(:close_path, data), do: data

  defp collect_item_data({:round_corner, :top_right}, data),
    do: update_position(data, %{x: @corner_size, y: @corner_size})

  defp collect_item_data({:round_corner, :bottom_right}, data),
    do: update_position(data, %{x: -@corner_size, y: @corner_size})

  defp collect_item_data({:round_corner, :bottom_left}, data),
    do: update_position(data, %{x: -@corner_size, y: -@corner_size})

  defp collect_item_data({:round_corner, :top_left}, data),
    do: update_position(data, %{x: -@corner_size, y: -@corner_size})

  defp collect_item_data({:round_corner, :inner_top_left}, data),
    do: update_position(data, %{x: -@corner_size, y: @corner_size})

  defp collect_item_data({:round_corner, :inner_bottom_left}, data),
    do: update_position(data, %{x: @corner_size, y: @corner_size})

  defp collect_item_data({:parent_action, id}, data) do
    key = {:action_in, id}
    value = %{x: data.x, y: data.y, height: @action_height, width: @action_width}
    connectors = Map.put(data.connectors, key, value)

    %{data | connectors: connectors}
    |> update_position(%{x: @action_width, y: @action_height})
    |> update_position(%{x: 0, y: -@action_height})
  end

  defp collect_item_data({:child_action, id}, data) do
    key = {:action_out, id}
    value = %{x: data.x + -@action_width, y: data.y, height: @action_height, width: @action_width}
    connectors = Map.put(data.connectors, key, value)

    %{data | connectors: connectors}
    |> update_position(%{x: -@action_width, y: @action_height})
    |> update_position(%{x: 0, y: -@action_height})
  end

  defp collect_item_data({:child_connector, id}, data) do
    key = {:connector_in, id}

    value = %{
      x: data.x - @connector_size,
      y: data.y,
      height: @connector_size,
      width: @connector_size
    }

    connectors = Map.put(data.connectors, key, value)

    %{data | connectors: connectors}
    |> update_position(%{x: -@connector_size, y: @connector_size})
    |> update_position(%{x: @connector_size, y: 0})
  end

  defp collect_item_data({:parent_connector, id}, data) do
    key = {:connector_out, id}

    value = %{
      x: data.x - @connector_size,
      y: data.y - @connector_size,
      height: @connector_size,
      width: @connector_size
    }

    connectors = Map.put(data.connectors, key, value)

    %{data | connectors: connectors}
    |> update_position(%{x: -@connector_size, y: -@connector_size})
    |> update_position(%{x: @connector_size, y: 0})
  end

  @spec update_position(property_data(), %{x: number(), y: number()}) :: property_data()
  defp update_position(data, %{x: x, y: y}) do
    new_x = data.x + x
    new_y = data.y + y

    %{
      data
      | x: new_x,
        y: new_y,
        width: max(data.width, new_x),
        height: max(data.height, new_y)
    }
  end
end
