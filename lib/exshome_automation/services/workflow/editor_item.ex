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
  end

  @spec update_position(t(), position()) :: t()
  def update_position(%__MODULE__{} = item, position) do
    %__MODULE__{
      item
      | position: normalize_position(position)
    }
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
end
