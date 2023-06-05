defmodule ExshomeAutomation.Services.Workflow.EditorItem do
  @moduledoc """
  Editor item.
  """
  defstruct [
    :id,
    :type,
    position: %{x: 0, y: 0}
  ]

  @type position() :: %{
          x: number(),
          y: number()
        }

  @type t() :: %__MODULE__{
          id: String.t(),
          position: position(),
          type: String.t()
        }

  @spec create(map()) :: t()
  def create(%{type: type, position: position}) when is_binary(type) do
    %__MODULE__{
      id: Ecto.UUID.autogenerate(),
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
end
