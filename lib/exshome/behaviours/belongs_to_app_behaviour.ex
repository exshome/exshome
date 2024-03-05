defmodule Exshome.Behaviours.BelongsToAppBehaviour do
  @moduledoc """
  Shows that module belongs to specific app.
  """

  @callback app() :: module()
end
