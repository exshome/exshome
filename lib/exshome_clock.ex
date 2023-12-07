defmodule ExshomeClock do
  @moduledoc """
  Application related to the clock.
  """

  alias ExshomeClock.Web.Live

  use Exshome.Behaviours.AppBehaviour,
    pages: [
      {Live.Clock, []},
      {Live.Settings, []}
    ],
    prefix: "clock",
    preview: Live.Preview,
    template_root: "./exshome_clock/web/templates"

  @impl AppBehaviour
  def can_start?, do: true
end
