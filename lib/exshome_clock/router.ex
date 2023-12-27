defmodule ExshomeClock.Router do
  @moduledoc """
  Routes for clock application.
  """

  use Exshome.Behaviours.RouterBehaviour, key: "clock"

  alias ExshomeClock.Web.Live

  scope "/app/clock" do
    live "/clock", Live.Clock
    live "/settings", Live.Settings
  end
end
