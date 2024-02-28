defmodule ExshomePlayer.Events.PlayerFileEndEvent do
  @moduledoc """
  Shows that file has ended.
  """

  use Exshome.Behaviours.EmitterBehaviour, type: Exshome.Event
end
