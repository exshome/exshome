defmodule ExshomeClock.Web.Live.Index do
  @moduledoc """
  Main clock page.
  """

  use ExshomeWeb.Live.AppPage,
    dependencies: [{ExshomeClock.Services.LocalTime, :time}],
    icon: "⏰"
end
