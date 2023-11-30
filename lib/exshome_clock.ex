defmodule ExshomeClock do
  @moduledoc """
  Application related to the clock.
  """

  alias ExshomeClock.Web.Live

  use ExshomeWeb.App,
    pages: [Live.Clock, Live.Settings],
    prefix: "clock",
    preview: Live.Preview

  use Exshome.Behaviours.AppBehaviour

  @impl AppBehaviour
  def app_settings,
    do: %AppBehaviour{
      pages: [Live.Clock, Live.Settings],
      prefix: "clock",
      preview: Live.Preview
    }
end
