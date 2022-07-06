defmodule ExshomeClock do
  @moduledoc """
  Application related to the clock.
  """

  alias ExshomeClock.Web.Live

  use Exshome.App,
    pages: [Live.Clock, Live.Settings],
    prefix: :clock,
    preview: Live.Preview
end
