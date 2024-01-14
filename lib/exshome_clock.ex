defmodule ExshomeClock do
  @moduledoc """
  Application related to the clock.
  """

  use Exshome.Behaviours.AppBehaviour

  @impl AppBehaviour
  def can_start?, do: true
end
