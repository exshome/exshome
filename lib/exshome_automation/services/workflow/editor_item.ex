defmodule ExshomeAutomation.Services.Workflow.EditorItem do
  @moduledoc """
  Editor item.
  """

  alias ExshomeAutomation.Services.Workflow.ItemConfig

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
          config: ItemConfig.t(),
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
        config: %ItemConfig{
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
      item.config
      |> ItemConfig.compute_svg_components()
      |> ItemConfig.svg_components_to_path()

    %__MODULE__{
      item
      | svg_path: svg_path
    }
  end
end
