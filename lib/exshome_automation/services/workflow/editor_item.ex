defmodule ExshomeAutomation.Services.Workflow.EditorItem do
  @moduledoc """
  Editor item.
  """

  defmodule Config do
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
  end

  defstruct [
    :id,
    :type,
    :config,
    :height,
    :width,
    :svg_path,
    position: %{x: 0, y: 0}
  ]

  @type position() :: %{
          x: number(),
          y: number()
        }

  @type t() :: %__MODULE__{
          id: String.t(),
          config: Config.t(),
          position: position(),
          height: number(),
          width: number(),
          svg_path: String.t(),
          type: String.t()
        }

  @spec create(map()) :: t()
  def create(%{type: type, position: position}) when is_binary(type) do
    default_values = available_types()[type]

    %__MODULE__{
      default_values
      | id: Ecto.UUID.autogenerate(),
        position: normalize_position(position),
        type: type
    }
    |> refresh_item()
  end

  @spec update_position(t(), position()) :: t()
  def update_position(%__MODULE__{} = item, position) do
    %__MODULE__{
      item
      | position: normalize_position(position)
    }
    |> refresh_item()
  end

  defp normalize_position(%{x: x, y: y}) do
    %{x: max(x, 0), y: max(y, 0)}
  end

  def available_types do
    %{
      "rect" => %__MODULE__{
        height: 46,
        width: 34,
        position: %{x: 0, y: 0},
        config: %Config{
          has_previous_action?: true,
          has_next_action?: true,
          has_parent_connection?: true,
          child_actions: [
            %{height: 3},
            %{height: 3}
          ],
          child_connections: [
            %{height: 3},
            %{height: 3}
          ]
        }
      }
    }
  end

  @spec refresh_item(t()) :: t()
  defp refresh_item(%__MODULE__{} = item) do
    svg_path =
      item
      |> compute_svg_components()
      |> Enum.map_join(" ", &svg_to_string/1)

    %__MODULE__{
      item
      | svg_path: svg_path
    }
  end

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
  def compute_svg_components(%__MODULE__{} = item) do
    []
    |> put_svg_component({:move, @offset_x, @offset_y})
    |> compute_component_top(item)
    |> put_svg_component({:round_corner, :top_right})
    |> compute_component_right(item)
    |> put_svg_component({:round_corner, :bottom_right})
    |> compute_component_bottom(item)
    |> put_svg_component({:round_corner, :bottom_left})
    |> compute_component_left(item)
    |> put_svg_component({:round_corner, :top_left})
    |> put_svg_component(:close_path)
    |> Enum.reverse()
  end

  @spec compute_component_top([svg_component()], t()) :: [svg_component()]
  defp compute_component_top(components, %__MODULE__{config: %Config{has_previous_action?: false}}) do
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
  defp compute_component_bottom(components, %__MODULE__{config: %Config{has_next_action?: false}}) do
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
         %__MODULE__{
           config: %Config{has_parent_connection?: false}
         } = item
       ) do
    height = compute_left_height(item)
    put_svg_component(components, {:vertical, -height})
  end

  defp compute_component_left(components, %__MODULE__{} = item) do
    height = compute_left_height(item)
    offset = height - @connector_height - @connector_offset

    components
    |> put_svg_component({:vertical, -offset})
    |> put_svg_component(:parent_connector)
    |> put_svg_component({:vertical, -@connector_offset})
  end

  defp compute_left_height(%__MODULE__{} = item) do
    %Config{child_actions: child_actions, child_connections: child_connections} = item.config

    connections_height =
      child_connections
      |> Enum.map(&max(&1.height, @component_height))
      |> Enum.sum()

    actions_height =
      child_actions
      |> Enum.map(&max(&1.height, @component_height))
      |> Enum.sum()

    actions_count = length(child_actions)
    action_separators_height = actions_count * @child_action_separator_height
    action_corners_height = actions_count * 2 * @corner_height
    total_actions_height = actions_height + action_separators_height + action_corners_height

    max(@component_height, connections_height) + total_actions_height
  end

  @spec compute_component_right([svg_component()], t()) :: [svg_component()]
  defp compute_component_right(components, %__MODULE__{
         config: %Config{child_actions: [], child_connections: []}
       }) do
    put_svg_component(components, {:vertical, @component_height})
  end

  defp compute_component_right(components, %__MODULE__{} = item) do
    components
    |> compute_child_connections(item)
    |> compute_child_actions(item)
  end

  @spec compute_child_connections([svg_component()], t()) :: [svg_component()]
  defp compute_child_connections(components, %__MODULE__{config: %Config{child_connections: []}}) do
    put_svg_component(components, {:vertical, @component_height})
  end

  defp compute_child_connections(components, %__MODULE__{config: %Config{} = config}) do
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
  defp compute_child_actions(components, %__MODULE__{config: %Config{child_actions: []}}) do
    components
  end

  defp compute_child_actions(components, %__MODULE__{config: %Config{} = config}) do
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
