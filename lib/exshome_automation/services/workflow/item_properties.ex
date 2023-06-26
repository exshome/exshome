defmodule ExshomeAutomation.Services.Workflow.ItemProperties do
  @moduledoc """
  Struct for storing item property settings
  """

  defstruct [
    :height,
    :width,
    connectors: %{}
  ]

  @type connector_key() ::
          :parent_connector | :parent_action | {:action | :connector, id :: String.t()}
  @type connector_type() :: :parent | :action | :connector
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

  @spec connector_type(connector_key()) :: connector_type()
  def connector_type(:parent_connector), do: :parent
  def connector_type(:parent_action), do: :parent
  def connector_type({:action, _}), do: :action
  def connector_type({:connector, _}), do: :connector
end
