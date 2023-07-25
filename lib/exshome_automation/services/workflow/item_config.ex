defmodule ExshomeAutomation.Services.Workflow.ItemConfig do
  @moduledoc """
  Editor item configuration.
  """
  alias ExshomeAutomation.Services.Workflow.ItemProperties

  defstruct [
    :label,
    :parent,
    :has_next_action?,
    child_connections: [],
    child_actions: []
  ]

  @type t() :: %__MODULE__{
          label: String.t(),
          parent: :connection | :action | nil,
          has_next_action?: boolean(),
          child_connections: [String.t()],
          child_actions: [String.t()]
        }

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
          | :parent_action
          | {:child_action, String.t()}
          | {:child_action, :next_action}
          | :parent_connector
          | {:child_connector, String.t()}

  @type child_data() :: %{
          id: String.t(),
          height: number(),
          width: number()
        }

  @type size_data() :: %{
          action: [child_data()],
          connection: [child_data()],
          width: number(),
          child_label_width: number()
        }

  @connector_size 4
  @connector_offset 2
  @outline_size 1
  @min_width 20
  @min_height 2 * @connector_offset + @connector_size + @outline_size
  @action_width 6
  @action_height 2
  @action_offset 2
  @labels_gap_size 6
  @child_action_empty_height 2
  @min_child_action_offset 5
  @child_action_separator_height 1
  @corner_size 1
  @letter_height 3
  @letter_width 1.85

  @spec compute_svg_components(t(), ItemProperties.connected_items()) :: [svg_component()]
  def compute_svg_components(%__MODULE__{} = config, connected_items) do
    max_child_label_width =
      config.child_actions
      |> Enum.map(&(String.length(&1) * @letter_width + @outline_size))
      |> Enum.max(fn -> @min_child_action_offset end)

    max_connection_label_width =
      config.child_connections
      |> Enum.map(&(String.length(&1) * @letter_width + @outline_size))
      |> Enum.max(fn -> 0 end)

    component_width =
      String.length(config.label) * @letter_width + max_connection_label_width + @labels_gap_size

    size_data = %{
      child_label_width: max_child_label_width,
      width: max(component_width, @min_width)
    }

    child_data = [
      {:action, config.child_actions, 0},
      {:connection, config.child_connections, @min_height}
    ]

    size_data =
      for {child_type, child_items, min_height} <- child_data, into: size_data do
        items =
          Enum.map(child_items, fn id ->
            key = ItemProperties.child_connector_key(child_type, id)
            connection = connected_items[key] || %{height: 0, width: 0}

            %{
              id: id,
              height: max(min_height, connection.height),
              width: max(@min_width, connection.width)
            }
          end)

        {child_type, items}
      end

    []
    |> put_svg_component({:move, @connector_size + @outline_size + @corner_size, @outline_size})
    |> compute_component_top(config, size_data)
    |> put_svg_component({:round_corner, :top_right})
    |> compute_component_right(config, size_data)
    |> put_svg_component({:round_corner, :bottom_right})
    |> compute_component_bottom(config, size_data)
    |> put_svg_component({:round_corner, :bottom_left})
    |> compute_component_left(config, size_data)
    |> put_svg_component({:round_corner, :top_left})
    |> put_svg_component(:close_path)
    |> Enum.reverse()
  end

  @spec compute_component_top([svg_component()], t(), size_data()) :: [svg_component()]
  defp compute_component_top(components, %__MODULE__{parent: :action}, %{width: width}) do
    offset = width - @action_offset - @action_width

    components
    |> put_svg_component({:horizontal, @action_offset})
    |> put_svg_component(:parent_action)
    |> put_svg_component({:horizontal, offset})
  end

  defp compute_component_top(components, %__MODULE__{}, %{width: width}) do
    put_svg_component(components, {:horizontal, width})
  end

  @spec compute_component_bottom([svg_component()], t(), size_data()) :: [svg_component()]
  defp compute_component_bottom(components, %__MODULE__{has_next_action?: false}, %{width: width}) do
    put_svg_component(components, {:horizontal, -width})
  end

  defp compute_component_bottom(components, %__MODULE__{}, %{width: width}) do
    offset = width - @action_offset - @action_width

    components
    |> put_svg_component({:horizontal, -offset})
    |> put_svg_component({:child_action, :next_action})
    |> put_svg_component({:horizontal, -@action_offset})
  end

  @spec compute_component_left([svg_component()], t(), size_data()) :: [svg_component()]
  defp compute_component_left(components, %__MODULE__{parent: :connection} = config, size_data) do
    height = compute_left_height(config, size_data)
    offset = height - @connector_size - @connector_offset

    components
    |> put_svg_component({:vertical, -offset})
    |> put_svg_component(:parent_connector)
    |> put_svg_component({:vertical, -@connector_offset})
  end

  defp compute_component_left(components, %__MODULE__{} = config, size_data) do
    height = compute_left_height(config, size_data)
    put_svg_component(components, {:vertical, -height})
  end

  defp compute_left_height(%__MODULE__{} = config, size_data) do
    connections_height =
      size_data.connection
      |> Enum.map(&max(&1.height, @min_height))
      |> Enum.sum()

    actions_height =
      size_data.action
      |> Enum.map(&(&1.height + @child_action_empty_height))
      |> Enum.sum()

    actions_count = length(config.child_actions)
    action_separators_height = actions_count * @child_action_separator_height
    action_corners_height = actions_count * 4 * @corner_size
    total_actions_height = actions_height + action_separators_height + action_corners_height

    max(@min_height, connections_height) + total_actions_height
  end

  @spec compute_component_right([svg_component()], t(), size_data()) :: [svg_component()]
  defp compute_component_right(
         components,
         %__MODULE__{child_actions: [], child_connections: []},
         _
       ) do
    put_svg_component(components, {:vertical, @min_height})
  end

  defp compute_component_right(components, %__MODULE__{} = config, size_data) do
    components
    |> compute_child_connections(config, size_data)
    |> compute_child_actions(config, size_data)
  end

  @spec compute_child_connections([svg_component()], t(), size_data()) :: [svg_component()]
  defp compute_child_connections(components, %__MODULE__{child_connections: []}, _) do
    put_svg_component(components, {:vertical, @min_height})
  end

  defp compute_child_connections(components, _config, size_data) do
    for %{height: height, id: id} <- size_data.connection, reduce: components do
      components ->
        remaining_offset = height - @connector_offset - @connector_size

        components
        |> put_svg_component({:vertical, @connector_offset})
        |> put_svg_component({:child_connector, id})
        |> put_svg_component({:vertical, remaining_offset})
    end
  end

  @spec compute_child_actions([svg_component()], t(), size_data()) :: [svg_component()]
  defp compute_child_actions(components, %__MODULE__{child_actions: []}, _) do
    components
  end

  defp compute_child_actions(components, _config, size_data) do
    child_action_width = size_data.width - size_data.child_label_width - @corner_size
    child_action_right_offset = child_action_width - @action_width - @action_offset

    for %{height: height, id: id} <- size_data.action, reduce: components do
      components ->
        components
        |> put_svg_component({:round_corner, :bottom_right})
        |> put_svg_component({:horizontal, -child_action_right_offset})
        |> put_svg_component({:child_action, id})
        |> put_svg_component({:horizontal, -@action_offset})
        |> put_svg_component({:round_corner, :inner_top_left})
        |> put_svg_component({:vertical, height + @child_action_empty_height})
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

  defp svg_to_string(:parent_action),
    do: "l #{@action_width / 2} 2 l #{@action_width / 2} -2"

  defp svg_to_string({:child_action, _}),
    do: "l -#{@action_width / 2} 2 l -#{@action_width / 2} -2"

  defp svg_to_string({:child_connector, _}) do
    vertical_offset = @connector_size / 8
    connector_radius = @connector_size / 2

    """
    v #{vertical_offset}
    l -#{connector_radius} -#{vertical_offset}
    a #{connector_radius} #{connector_radius} 0 0 0 0 #{@connector_size}
    l #{connector_radius} -#{vertical_offset}
    v #{vertical_offset}
    """
  end

  defp svg_to_string(:parent_connector) do
    vertical_offset = @connector_size / 8
    connector_radius = @connector_size / 2

    """
    v -#{vertical_offset}
    l -#{connector_radius} #{vertical_offset}
    a #{connector_radius} #{connector_radius} 0 0 1 0 -#{@connector_size}
    l #{connector_radius} #{vertical_offset}
    v -#{vertical_offset}
    """
  end

  @type property_data() :: %{
          x: number(),
          y: number(),
          width: number(),
          height: number(),
          connectors: ItemProperties.connectors()
        }

  @spec compute_item_properties([svg_component()], t()) :: ItemProperties.t()
  def compute_item_properties(svg_components, %__MODULE__{} = config) do
    initial_data = %{x: 0, y: 0, width: 0, height: 0, connectors: %{}}

    item_data =
      for component <- svg_components, reduce: initial_data do
        intermediate_data -> collect_item_data(component, intermediate_data)
      end

    height = item_data.height + @outline_size
    width = item_data.width + @outline_size

    %ItemProperties{
      height: height,
      width: width,
      connectors: item_data.connectors,
      labels: compute_labels(config, item_data),
      raw_size: %{
        height:
          height - 2 * @outline_size - if(config.has_next_action?, do: @action_height, else: 0),
        width: width - 2 * @outline_size - @connector_size
      }
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

  defp collect_item_data(:parent_action, data) do
    key = :parent_action
    value = %{x: data.x, y: data.y, height: @action_height, width: @action_width}
    connectors = Map.put(data.connectors, key, value)

    %{data | connectors: connectors}
    |> update_position(%{x: @action_width, y: @action_height})
    |> update_position(%{x: 0, y: -@action_height})
  end

  defp collect_item_data({:child_action, id}, data) do
    key = {:action, id}
    value = %{x: data.x + -@action_width, y: data.y, height: @action_height, width: @action_width}
    connectors = Map.put(data.connectors, key, value)

    %{data | connectors: connectors}
    |> update_position(%{x: -@action_width, y: @action_height})
    |> update_position(%{x: 0, y: -@action_height})
  end

  defp collect_item_data({:child_connector, id}, data) do
    key = {:connection, id}

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

  defp collect_item_data(:parent_connector, data) do
    key = :parent_connector

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

  @spec compute_labels(t(), property_data()) :: [ItemProperties.label()]
  defp compute_labels(%__MODULE__{} = config, property_data) do
    title_label = %{
      text: config.label,
      x: @outline_size * 2 + @connector_size,
      y: @outline_size * 2 + @action_height + @letter_height
    }

    connection_labels =
      for label <- config.child_connections do
        %{x: x, y: y} = property_data.connectors[{:connection, label}]

        %{
          text: label,
          x: x - @outline_size - String.length(label) * @letter_width,
          y: y + @letter_height
        }
      end

    action_labels =
      for label <- config.child_actions do
        %{y: y} = property_data.connectors[{:action, label}]

        %{
          text: label,
          x: @outline_size * 2 + @connector_size,
          y: y + @letter_height - @outline_size
        }
      end

    [title_label] ++ connection_labels ++ action_labels
  end

  @spec min_child_item_size() :: %{atom() => ItemProperties.size()}
  def min_child_item_size do
    %{
      connection: %{height: @min_height + 2 * @corner_size, width: @min_width + 2 * @corner_size}
    }
  end
end
