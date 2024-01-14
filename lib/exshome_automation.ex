defmodule ExshomeAutomation do
  @moduledoc """
  Application related to automation.
  """

  use Exshome.Behaviours.AppBehaviour

  @impl AppBehaviour
  def can_start?, do: true
end
